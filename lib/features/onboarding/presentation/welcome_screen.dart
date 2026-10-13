import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:love_app/core/providers/app_providers.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:love_app/features/onboarding/presentation/create_profile_screen.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isGetStartedLoading = false;
  bool _isLogInLoading = false;
  String? _errorMessage;

  Future<void> _handleGetStarted() async {
    setState(() {
      _isGetStartedLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(coupleRepositoryProvider.notifier);
      await repo.signInWithGoogle();
      if (mounted) {
        setState(() => _isGetStartedLoading = false);
        final currentRepo = ref.read(coupleRepositoryProvider);
        if (currentRepo.hasCompletedOnboarding || currentRepo.hasCreatedProfile) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        } else if (currentRepo.isSignedIn) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGetStartedLoading = false;
          _errorMessage = 'Sign-In error: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  Future<void> _handleLogIn() async {
    setState(() {
      _isLogInLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(coupleRepositoryProvider.notifier);
      await repo.signInWithGoogle();
      if (mounted) {
        setState(() => _isLogInLoading = false);
        final currentRepo = ref.read(coupleRepositoryProvider);
        if (currentRepo.hasCompletedOnboarding || currentRepo.hasCreatedProfile) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        } else if (currentRepo.isSignedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppTheme.plum,
              content: Text('No existing space found with this account. Let\'s set up your profile!'),
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLogInLoading = false;
          _errorMessage = 'Log-In error: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for OAuth callbacks that complete asynchronously
    ref.listen(coupleRepositoryProvider, (previous, next) {
      if (next.hasCompletedOnboarding || next.hasCreatedProfile) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else if (next.isSignedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // App Logo / Icon with glowing halo
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.blush,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.roseGold.withValues(alpha: 0.6), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.crimson.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 52,
                    height: 52,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.favorite_rounded,
                      color: AppTheme.crimson,
                      size: 46,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title & Subtitle
              const Text(
                'LoveSync',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.plum,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A private, zero-pressure space for intimate connection & rhythm.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Feature Highlights Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.blush),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildFeatureRow(
                      icon: Icons.lock_outline_rounded,
                      title: 'Zero-Knowledge Privacy',
                      description: 'Direct couple encryption. Your intimacy data belongs only to you two.',
                    ),
                    const Divider(height: 22, color: AppTheme.blush),
                    _buildFeatureRow(
                      icon: Icons.local_fire_department_rounded,
                      title: 'Double-Blind Mood Match',
                      description: 'No pressure, no rejection. You only know when you are both in the mood.',
                    ),
                    const Divider(height: 22, color: AppTheme.blush),
                    _buildFeatureRow(
                      icon: Icons.calendar_today_rounded,
                      title: 'Cycle & Rhythm Sync',
                      description: 'Stay in tune with fertile and safe intimacy days together.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Error display if any
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.fertileRedBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.fertileRed.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 18, color: AppTheme.fertileRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.fertileRed,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // PATH 1: GET STARTED (NEW USERS)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isGetStartedLoading || _isLogInLoading) ? null : _handleGetStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.crimson,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: AppTheme.crimson.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: _isGetStartedLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 14),

              // PATH 2: LOG IN (RETURNING USERS)
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: (_isGetStartedLoading || _isLogInLoading) ? null : _handleLogIn,
                    child: Center(
                      child: _isLogInLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: AppTheme.crimson),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/google_logo.png',
                                  width: 20,
                                  height: 20,
                                  errorBuilder: (ctx, err, st) => const Icon(
                                    Icons.login_rounded,
                                    size: 20,
                                    color: AppTheme.plum,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'I Already Have an Account • Log In',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.plum,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Security & Privacy footnote
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    'Protected by Google OAuth & Supabase Realtime',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.blush,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.crimson, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.plum,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
