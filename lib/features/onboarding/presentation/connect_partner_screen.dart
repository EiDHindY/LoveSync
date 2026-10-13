import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:love_app/core/providers/app_providers.dart';
import 'package:love_app/core/services/couple_repository.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:love_app/features/onboarding/presentation/create_profile_screen.dart';

class ConnectPartnerScreen extends ConsumerStatefulWidget {
  const ConnectPartnerScreen({super.key});

  @override
  ConsumerState<ConnectPartnerScreen> createState() => _ConnectPartnerScreenState();
}

class _ConnectPartnerScreenState extends ConsumerState<ConnectPartnerScreen> {
  final _codeController = TextEditingController();
  bool _isEnteringCode = false;
  bool _copied = false;
  bool _isLoading = false;
  String? _errorMessage;
  late CoupleRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(coupleRepositoryProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo.startWaitingBeacon();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _repo.stopWaitingBeacon();
    super.dispose();
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _shareCode(String code) async {
    await SharePlus.instance.share(
      ShareParams(
        text: 'Hey! Join our private LoveSync space using invite code $code 💕',
        subject: 'LoveSync Partner Invite',
      ),
    );
  }

  Future<void> _handleJoinCode() async {
    final raw = _codeController.text.trim();
    if (raw.isEmpty) {
      setState(() => _errorMessage = 'Please enter an invite code.');
      return;
    }

    final code = CoupleRepository.normalizeInviteCode(raw);
    _codeController.text = code;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = ref.read(coupleRepositoryProvider.notifier);
    final success = await repo.joinCoupleWithCode(code: code);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      } else {
        setState(() => _errorMessage = 'Could not pair with this code. Check with your partner.');
      }
    }
  }

  Future<void> _handleSkipSolo() async {
    final repo = ref.read(coupleRepositoryProvider.notifier);
    await repo.completeOnboardingSolo();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleEditProfile() async {
    final repo = ref.read(coupleRepositoryProvider.notifier);
    await repo.returnToProfileSetup();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(coupleRepositoryProvider);

    // If already paired, auto-navigate immediately
    if (repo.isPaired && repo.partnerName.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false,
          );
        }
      });
    }

    // If partner joined in real-time while on this screen, auto-navigate!
    ref.listen(coupleRepositoryProvider, (prev, next) {
      if (next.isPaired && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.safeGreen,
            content: Text(next.partnerName.isNotEmpty
                ? 'Partner Connected! 💕 ${next.partnerName} has joined your space!'
                : 'Partner Connected! 💕'),
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
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
              const SizedBox(height: 12),
              // Step Indicator Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.blush,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'STEP 2 OF 2 • CONNECT YOUR PARTNER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.crimson,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Header Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.blush,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.roseGold.withValues(alpha: 0.6), width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.favorite_rounded, color: AppTheme.crimson, size: 38),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Hi, ${repo.currentUserName}!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.plum,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your profile is created. LoveSync is designed for two.\nHow would you like to link with your partner?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 24),

              // Mode Switcher: Share Code vs Enter Partner's Code
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.blush.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isEnteringCode = false;
                          _errorMessage = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isEnteringCode ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: !_isEnteringCode
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Share My Invite Code',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: !_isEnteringCode ? AppTheme.crimson : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isEnteringCode = true;
                          _errorMessage = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isEnteringCode ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isEnteringCode
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'I Have a Code to Join',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _isEnteringCode ? AppTheme.crimson : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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
                          style: const TextStyle(color: AppTheme.fertileRed, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Content based on selected mode
              if (!_isEnteringCode) ...[
                // Card 1: Share Your Code Hub
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
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
                    children: [
                      const Text(
                        'YOUR PRIVATE INVITE CODE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppTheme.plum,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        repo.inviteCode,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          color: AppTheme.crimson,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.crimson,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => _shareCode(repo.inviteCode),
                              icon: const Icon(Icons.share_rounded, size: 18),
                              label: const Text('Share Code'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: AppTheme.roseGold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => _copyCode(repo.inviteCode),
                              icon: Icon(_copied ? Icons.check : Icons.copy, size: 18, color: AppTheme.crimson),
                              label: Text(_copied ? 'Copied!' : 'Copy Code', style: const TextStyle(color: AppTheme.crimson)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Live Radar / Listener Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.blush),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.crimson),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Listening for partner... Once they enter this code, you will connect automatically!',
                                style: TextStyle(fontSize: 11, color: AppTheme.plum, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Card 2: Enter Partner's Code
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
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
                    children: [
                      const Icon(Icons.link_rounded, color: AppTheme.crimson, size: 36),
                      const SizedBox(height: 10),
                      const Text(
                        'Enter Partner\'s Invite Code',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.plum),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter the 6-character code shown on your partner\'s screen (e.g. LOVE-7821).',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          color: AppTheme.crimson,
                        ),
                        decoration: InputDecoration(
                          hintText: 'LOVE-XXXX',
                          filled: true,
                          fillColor: AppTheme.backgroundLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppTheme.blush),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleJoinCode,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Connect to Partner', style: TextStyle(fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Return to Step 1 (Edit Name & Gender/Cycle Role)
              TextButton.icon(
                onPressed: _handleEditProfile,
                icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.crimson),
                label: const Text(
                  'Edit Name & Role (Step 1)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.crimson),
                ),
              ),

              // Skip for now & explore solo
              TextButton.icon(
                onPressed: _handleSkipSolo,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey),
                label: const Text(
                  'Continue to Dashboard & Invite Later',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
