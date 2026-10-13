import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:love_app/core/providers/app_providers.dart';
import 'package:love_app/core/services/couple_repository.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/dashboard/presentation/dashboard_screen.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _nameController = TextEditingController();
  bool _tracksCycle = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final repo = ref.read(coupleRepositoryProvider);
        if (repo.currentUserName.isNotEmpty && _nameController.text.isEmpty) {
          _nameController.text = repo.currentUserName;
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(coupleRepositoryProvider.notifier);
      await repo.signInWithGoogle();
      if (mounted) {
        setState(() => _isGoogleLoading = false);
        final currentRepo = ref.read(coupleRepositoryProvider);
        if (currentRepo.hasCompletedOnboarding || currentRepo.hasCreatedProfile) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
          _errorMessage = 'Google Sign-In: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  Future<void> _handleContinue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name or nickname.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = ref.read(coupleRepositoryProvider.notifier);
    await repo.createPersonalProfile(
      displayName: name,
      tracksCycle: _tracksCycle,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(coupleRepositoryProvider);
    if (repo.isSignedIn && repo.currentUserName.isNotEmpty && _nameController.text.isEmpty) {
      _nameController.text = repo.currentUserName;
    }

    ref.listen(coupleRepositoryProvider, (previous, next) {
      if (next.currentUserName.isNotEmpty && _nameController.text.isEmpty) {
        _nameController.text = next.currentUserName;
      }
      if (next.hasCompletedOnboarding ||
          (next.hasCreatedProfile && !(previous?.hasCreatedProfile ?? false))) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Step Indicator Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.blush,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  repo.isSignedIn
                      ? 'COMPLETE YOUR PROFILE'
                      : 'WELCOME • SIGN IN TO START',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.crimson,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header Icon
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppTheme.blush,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.roseGold.withValues(alpha: 0.6), width: 2),
                ),
                child: Center(
                  child: Icon(
                    repo.isSignedIn ? Icons.person_rounded : Icons.favorite_rounded,
                    color: AppTheme.crimson,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                repo.isSignedIn ? 'Complete Your Profile' : 'Welcome to LoveSync',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.plum,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                repo.isSignedIn
                    ? 'Confirm your nickname and cycle tracking preferences before connecting with your partner.'
                    : 'A private, zero-pressure space for you and your partner. Sign in with Google to create or restore your space on any device.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.4),
              ),
              const SizedBox(height: 28),

              // Error banner if any
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

              // MANDATORY GOOGLE AUTH VIEW
              if (!repo.isSignedIn) ...[
                _buildGoogleSignInCard(),
                const SizedBox(height: 36),
                _buildSecurityFootnote(),
              ] else ...[
                // SIGNED-IN PROFILE DETAILS VIEW
                _buildSignedInAccountPill(repo),
                const SizedBox(height: 20),
                _buildProfileFormCard(),
                const SizedBox(height: 24),
                _buildContinueButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isGoogleLoading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.crimson),
                  )
                else ...[
                  Image.asset(
                    'assets/images/google_logo.png',
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF222222),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityFootnote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.blush),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 16, color: AppTheme.plum),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Sign in required to restore & sync your couple space on any device.',
              style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignedInAccountPill(CoupleRepository repo) {
    final avatarUrl = repo.userAvatarUrl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.blush.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.crimson.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppTheme.crimson.withValues(alpha: 0.35), width: 1.5),
            ),
            child: ClipOval(
              child: avatarUrl.isNotEmpty
                  ? Image.network(
                      avatarUrl,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      errorBuilder: (_, _, _) => _buildAvatarFallback(repo),
                    )
                  : _buildAvatarFallback(repo),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Signed in with Google',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.plum,
                  ),
                ),
                Text(
                  repo.userEmail,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => ref.read(coupleRepositoryProvider.notifier).signOut(),
            child: const Text('Sign out', style: TextStyle(fontSize: 12, color: AppTheme.crimson)),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(CoupleRepository repo) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          'assets/images/google_logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildProfileFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.blush),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR NAME OR NICKNAME',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AppTheme.crimson,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'e.g. Alex, Sam, Honey...',
              prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.crimson),
              filled: true,
              fillColor: AppTheme.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.blush),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'MENSTRUAL CYCLE TRACKING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AppTheme.crimson,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Do you experience menstrual cycles to track for intimacy safety?',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildCycleOption(
                hasCycle: true,
                title: 'I Track My Cycle',
                subtitle: 'Logs periods & safe window',
                icon: Icons.calendar_month_rounded,
              ),
              const SizedBox(width: 10),
              _buildCycleOption(
                hasCycle: false,
                title: 'I Do Not Track',
                subtitle: 'Views safe days & alerts',
                icon: Icons.male_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleContinue,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.arrow_forward_rounded, size: 20),
        label: const Text('Continue to Dashboard', style: TextStyle(fontSize: 15)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildCycleOption({
    required bool hasCycle,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _tracksCycle == hasCycle;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tracksCycle = hasCycle),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.blush.withValues(alpha: 0.6) : AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.crimson : AppTheme.blush,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppTheme.crimson : Colors.grey.shade600, size: 24),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? AppTheme.crimson : AppTheme.plum,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
