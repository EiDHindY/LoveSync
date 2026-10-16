-- Direct Message (DM) chat messages table with couple RLS
CREATE TABLE IF NOT EXISTS public.couple_chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    couple_id UUID NOT NULL REFERENCES public.couples(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    text TEXT NOT NULL DEFAULT '',
    image_url TEXT,
    is_view_once BOOLEAN NOT NULL DEFAULT false,
    is_viewed BOOLEAN NOT NULL DEFAULT false,
    reactions JSONB NOT NULL DEFAULT '{}'::jsonb,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_couple_created
ON public.couple_chat_messages(couple_id, created_at ASC);

ALTER TABLE public.couple_chat_messages ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'couple_chat_messages' AND policyname = 'couple_chat_select_policy'
    ) THEN
        CREATE POLICY "couple_chat_select_policy"
        ON public.couple_chat_messages
        FOR SELECT
        TO public
        USING (
            EXISTS (
                SELECT 1 FROM public.couples c
                WHERE c.id = couple_chat_messages.couple_id
                  AND (c.created_by = auth.uid() OR c.partner_id = auth.uid())
            )
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'couple_chat_messages' AND policyname = 'couple_chat_insert_policy'
    ) THEN
        CREATE POLICY "couple_chat_insert_policy"
        ON public.couple_chat_messages
        FOR INSERT
        TO public
        WITH CHECK (
            EXISTS (
                SELECT 1 FROM public.couples c
                WHERE c.id = couple_chat_messages.couple_id
                  AND (c.created_by = auth.uid() OR c.partner_id = auth.uid())
            )
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'couple_chat_messages' AND policyname = 'couple_chat_update_policy'
    ) THEN
        CREATE POLICY "couple_chat_update_policy"
        ON public.couple_chat_messages
        FOR UPDATE
        TO public
        USING (
            EXISTS (
                SELECT 1 FROM public.couples c
                WHERE c.id = couple_chat_messages.couple_id
                  AND (c.created_by = auth.uid() OR c.partner_id = auth.uid())
            )
        )
        WITH CHECK (
            EXISTS (
                SELECT 1 FROM public.couples c
                WHERE c.id = couple_chat_messages.couple_id
                  AND (c.created_by = auth.uid() OR c.partner_id = auth.uid())
            )
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'couple_chat_messages' AND policyname = 'couple_chat_delete_policy'
    ) THEN
        CREATE POLICY "couple_chat_delete_policy"
        ON public.couple_chat_messages
        FOR DELETE
        TO public
        USING (
            EXISTS (
                SELECT 1 FROM public.couples c
                WHERE c.id = couple_chat_messages.couple_id
                  AND (c.created_by = auth.uid() OR c.partner_id = auth.uid())
            )
        );
    END IF;
END $$;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'chat_images',
    'chat_images',
    true,
    20971520,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
ON CONFLICT (id) DO NOTHING;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'objects' AND policyname = 'chat_images_select_policy'
    ) THEN
        CREATE POLICY "chat_images_select_policy"
        ON storage.objects
        FOR SELECT
        TO public
        USING (bucket_id = 'chat_images');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'objects' AND policyname = 'chat_images_insert_policy'
    ) THEN
        CREATE POLICY "chat_images_insert_policy"
        ON storage.objects
        FOR INSERT
        TO public
        WITH CHECK (bucket_id = 'chat_images');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'objects' AND policyname = 'chat_images_update_policy'
    ) THEN
        CREATE POLICY "chat_images_update_policy"
        ON storage.objects
        FOR UPDATE
        TO public
        USING (bucket_id = 'chat_images');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'objects' AND policyname = 'chat_images_delete_policy'
    ) THEN
        CREATE POLICY "chat_images_delete_policy"
        ON storage.objects
        FOR DELETE
        TO public
        USING (bucket_id = 'chat_images');
    END IF;
END $$;
