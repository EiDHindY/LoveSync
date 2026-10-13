-- ==============================================================================
-- LoveSync Database Schema & Zero-Knowledge Security Functions
-- Migration: 20261012_init_lovesync.sql
-- ==============================================================================

-- 1. COUPLES TABLE
CREATE TABLE IF NOT EXISTS public.couples (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invite_code TEXT UNIQUE NOT NULL,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    partner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    paired_at TIMESTAMPTZ,
    default_cycle_length INTEGER NOT NULL DEFAULT 28,
    default_period_length INTEGER NOT NULL DEFAULT 5,
    safety_buffer_days INTEGER NOT NULL DEFAULT 2,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2. PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    couple_id UUID REFERENCES public.couples(id) ON DELETE SET NULL,
    display_name TEXT,
    role TEXT DEFAULT 'partner', -- 'husband', 'wife', 'partner'
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 3. MOOD SIGNALS TABLE (Double-Blind Storage)
CREATE TABLE IF NOT EXISTS public.mood_signals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    couple_id UUID REFERENCES public.couples(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    signal_date DATE NOT NULL,
    in_the_mood BOOLEAN NOT NULL DEFAULT false,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    UNIQUE(couple_id, user_id, signal_date)
);

-- 4. CYCLE LOGS TABLE
CREATE TABLE IF NOT EXISTS public.cycle_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    couple_id UUID REFERENCES public.couples(id) ON DELETE CASCADE NOT NULL,
    logged_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    cycle_length INTEGER NOT NULL DEFAULT 28,
    period_length INTEGER NOT NULL DEFAULT 5,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 5. SCHEDULED INTIMACY TABLE
CREATE TABLE IF NOT EXISTS public.scheduled_intimacy (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    couple_id UUID REFERENCES public.couples(id) ON DELETE CASCADE NOT NULL,
    proposed_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    scheduled_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'accepted', 'counter_offered', 'rainchecked', 'completed'
    counter_scheduled_at TIMESTAMPTZ,
    response_note TEXT,
    vibe_check_status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'confirmed', 'converted_cuddle'
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
ALTER TABLE public.couples ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mood_signals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cycle_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scheduled_intimacy ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they already exist
DROP POLICY IF EXISTS "Users can access self and partner profile" ON public.profiles;
DROP POLICY IF EXISTS "Couples read/update access for members" ON public.couples;
DROP POLICY IF EXISTS "Couple members can access cycle logs" ON public.cycle_logs;
DROP POLICY IF EXISTS "Couple members can access scheduled intimacy" ON public.scheduled_intimacy;
DROP POLICY IF EXISTS "Users can only read their own mood signal" ON public.mood_signals;
DROP POLICY IF EXISTS "Users can insert their own mood signal" ON public.mood_signals;
DROP POLICY IF EXISTS "Users can update their own mood signal" ON public.mood_signals;

-- Profiles: Users can read and update their own profile and their partner's profile
CREATE POLICY "Users can access self and partner profile"
ON public.profiles FOR ALL
USING (
    id = auth.uid() OR
    couple_id IN (
        SELECT id FROM public.couples WHERE created_by = auth.uid() OR partner_id = auth.uid()
    )
);

-- Couples: Members of the couple can access their couple row
CREATE POLICY "Couples read/update access for members"
ON public.couples FOR ALL
USING (
    created_by = auth.uid() OR partner_id = auth.uid()
);

-- Cycle Logs: Accessible by both members of the couple
CREATE POLICY "Couple members can access cycle logs"
ON public.cycle_logs FOR ALL
USING (
    couple_id IN (
        SELECT id FROM public.couples WHERE created_by = auth.uid() OR partner_id = auth.uid()
    )
);

-- Scheduled Intimacy: Accessible by both members of the couple
CREATE POLICY "Couple members can access scheduled intimacy"
ON public.scheduled_intimacy FOR ALL
USING (
    couple_id IN (
        SELECT id FROM public.couples WHERE created_by = auth.uid() OR partner_id = auth.uid()
    )
);

-- Mood Signals Direct RLS:
-- CRITICAL PRIVACY RULE: A user can ONLY directly SELECT, INSERT, or UPDATE their OWN mood signal.
CREATE POLICY "Users can only read their own mood signal"
ON public.mood_signals FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own mood signal"
ON public.mood_signals FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own mood signal"
ON public.mood_signals FOR UPDATE
USING (user_id = auth.uid());

-- ==============================================================================
-- ZERO-KNOWLEDGE RPC FUNCTIONS
-- ==============================================================================

-- 1. GET DAILY MOOD STATUS (Security Definer)
CREATE OR REPLACE FUNCTION public.get_daily_mood_status(p_date DATE)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_couple_id UUID;
    v_partner_id UUID;
    v_user_mood BOOLEAN := false;
    v_partner_mood BOOLEAN := false;
    v_is_match BOOLEAN := false;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Retrieve user's couple and partner ID
    SELECT id, CASE WHEN created_by = v_uid THEN partner_id ELSE created_by END
    INTO v_couple_id, v_partner_id
    FROM public.couples
    WHERE (created_by = v_uid OR partner_id = v_uid) AND partner_id IS NOT NULL;

    IF v_couple_id IS NULL THEN
        RETURN json_build_object(
            'has_couple', false,
            'user_mood', false,
            'is_match', false,
            'signal_date', p_date
        );
    END IF;

    -- Check current user's mood for p_date
    SELECT in_the_mood INTO v_user_mood
    FROM public.mood_signals
    WHERE couple_id = v_couple_id AND user_id = v_uid AND signal_date = p_date;

    IF v_user_mood IS NULL THEN
        v_user_mood := false;
    END IF;

    -- Only check partner's mood if user is in the mood
    IF v_user_mood = true THEN
        SELECT in_the_mood INTO v_partner_mood
        FROM public.mood_signals
        WHERE couple_id = v_couple_id AND user_id = v_partner_id AND signal_date = p_date;

        IF v_partner_mood = true THEN
            v_is_match := true;
        END IF;
    END IF;

    RETURN json_build_object(
        'has_couple', true,
        'couple_id', v_couple_id,
        'user_mood', v_user_mood,
        'is_match', v_is_match,
        'signal_date', p_date
    );
END;
$$;

-- 2. TOGGLE MOOD SIGNAL
CREATE OR REPLACE FUNCTION public.toggle_mood_signal(p_date DATE, p_in_the_mood BOOLEAN)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_couple_id UUID;
BEGIN
    SELECT id INTO v_couple_id
    FROM public.couples
    WHERE (created_by = v_uid OR partner_id = v_uid);

    IF v_couple_id IS NULL THEN
        RAISE EXCEPTION 'User does not belong to a couple';
    END IF;

    INSERT INTO public.mood_signals (couple_id, user_id, signal_date, in_the_mood, updated_at)
    VALUES (v_couple_id, v_uid, p_date, p_in_the_mood, timezone('utc'::text, now()))
    ON CONFLICT (couple_id, user_id, signal_date)
    DO UPDATE SET in_the_mood = EXCLUDED.in_the_mood, updated_at = timezone('utc'::text, now());

    RETURN public.get_daily_mood_status(p_date);
END;
$$;

-- 3. PAIR COUPLE VIA INVITE CODE
CREATE OR REPLACE FUNCTION public.pair_couple(p_invite_code TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_couple_id UUID;
    v_created_by UUID;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT id, created_by INTO v_couple_id, v_created_by
    FROM public.couples
    WHERE UPPER(invite_code) = UPPER(TRIM(p_invite_code)) AND partner_id IS NULL;

    IF v_couple_id IS NULL THEN
        RAISE EXCEPTION 'Invalid or already used invite code';
    END IF;

    IF v_created_by = v_uid THEN
        RAISE EXCEPTION 'Cannot pair with yourself';
    END IF;

    UPDATE public.couples
    SET partner_id = v_uid, paired_at = timezone('utc'::text, now())
    WHERE id = v_couple_id;

    UPDATE public.profiles
    SET couple_id = v_couple_id
    WHERE id = v_uid;

    RETURN json_build_object(
        'success', true,
        'couple_id', v_couple_id
    );
END;
$$;

-- 4. Enable Realtime Publications safely
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'mood_signals'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.mood_signals;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'cycle_logs'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.cycle_logs;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'scheduled_intimacy'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.scheduled_intimacy;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'couples'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.couples;
    END IF;
END $$;
