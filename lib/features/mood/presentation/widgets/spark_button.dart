import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/mood/domain/mood_status.dart';

class SparkButton extends StatefulWidget {
  final MoodStatus moodStatus;
  final FutureOr<void> Function() onToggle;
  final String? partnerName;
  final String? userName;

  const SparkButton({
    super.key,
    required this.moodStatus,
    required this.onToggle,
    this.partnerName,
    this.userName,
  });

  @override
  State<SparkButton> createState() => _SparkButtonState();
}

class _SparkButtonState extends State<SparkButton>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  late AnimationController _breathingController;
  late Animation<double> _breathingScale;
  late Animation<double> _breathingOpacity;

  Timer? _countdownTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    if (widget.moodStatus.isMatch) {
      _confettiController.play();
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 4.0, end: 20.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _breathingScale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    _breathingOpacity = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _handleToggle() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    HapticFeedback.mediumImpact();
    _pulseController.repeat(reverse: true);

    try {
      await widget.onToggle();
    } finally {
      if (mounted) {
        _pulseController.stop();
        _pulseController.reset();
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant SparkButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.moodStatus.isMatch && widget.moodStatus.isMatch) {
      HapticFeedback.heavyImpact();
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _confettiController.dispose();
    _pulseController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  DateTime _getExpiryTime(DateTime now) {
    if (now.hour >= 4 && now.hour < 16) {
      return DateTime(now.year, now.month, now.day, 16, 0);
    } else if (now.hour >= 16) {
      final tomorrow = now.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 4, 0);
    } else {
      return DateTime(now.year, now.month, now.day, 4, 0);
    }
  }

  String _formatRemainingTime(DateTime now, bool isMatch) {
    final expiry = _getExpiryTime(now);
    final diff = expiry.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final targetTimeStr = (expiry.hour == 16) ? '4:00 PM' : '4:00 AM';
    final remainingStr = hours > 0
        ? '${hours}h ${minutes}m left'
        : (minutes <= 1 ? '1m left' : '${minutes}m left');

    if (isMatch) {
      return 'Match active until $targetTimeStr ($remainingStr)';
    } else {
      return 'Spark resets at $targetTimeStr ($remainingStr)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMatch = widget.moodStatus.isMatch;
    final isLit = widget.moodStatus.userInTheMood;
    final partnerName = (widget.partnerName != null && widget.partnerName!.isNotEmpty)
        ? widget.partnerName!
        : 'your partner';
    final userName = (widget.userName != null && widget.userName!.isNotEmpty)
        ? widget.userName!
        : 'You';

    return Stack(
      alignment: Alignment.center,
      children: [
        // Confetti Celebration
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              AppTheme.crimson,
              AppTheme.roseGold,
              Color(0xFFFFD700),
              Color(0xFFFF4081),
              AppTheme.deepBerry,
            ],
          ),
        ),

        if (isMatch)
          _buildMutualMatchBanner(context, partnerName, userName)
        else
          _buildHeroDoubleBlindCard(context, isLit, partnerName),
      ],
    );
  }

  /// Stitch Hero: Mutual Sync Achieved Celebration Banner
  Widget _buildMutualMatchBanner(BuildContext context, String partnerName, String userName) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6B113B),
            Color(0xFFB61D46),
            Color(0xFF4A0025),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B113B).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'MUTUAL SYNC ACHIEVED',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: Colors.white,
                  ),
                ),
              ),
              // Overlapping Avatar initials
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: AppTheme.primaryFixed,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'Y',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.plum,
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-6, 0),
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: AppTheme.secondaryContainer,
                      child: Text(
                        partnerName.isNotEmpty ? partnerName[0].toUpperCase() : 'P',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Text(
                'The Spark is Lit!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.favorite_rounded, color: AppTheme.primaryFixed, size: 24),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Both of you are in the mood tonight. A secret match made in heaven.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          // Timer badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 13, color: Colors.white70),
                const SizedBox(width: 5),
                Text(
                  _formatRemainingTime(DateTime.now(), true),
                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleToggle,
                  icon: const Icon(Icons.light_mode_rounded, size: 18, color: AppTheme.crimson),
                  label: const Text('Celebrate & Turn Off'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.deepBerry,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Stitch Hero: 'Light My Spark' Double-Blind Mood Switch Card
  Widget _buildHeroDoubleBlindCard(BuildContext context, bool isLit, String partnerName) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceContainerLow,
            AppTheme.surfaceContainer,
            AppTheme.surfaceContainerHigh.withValues(alpha: 0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(
          color: isLit
              ? AppTheme.roseGold.withValues(alpha: 0.7)
              : AppTheme.blush.withValues(alpha: 0.9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B113B).withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Column(
        children: [
          // Tag / Status Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.favorite_rounded, size: 14, color: AppTheme.crimson),
                SizedBox(width: 6),
                Text(
                  'Double-Blind Desired Mode',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.deepBerry,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Main Heading
          const Text(
            'In the mood tonight?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.deepBerry,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),

          // Reassurance Subtext
          Text(
            '$partnerName won\'t be notified unless they also light their spark. Zero guilt, zero rejection.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.85),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 22),

          // Centerpiece Interactive Pulsing Spark Toggle Button
          GestureDetector(
            onTap: _isLoading ? null : _handleToggle,
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseController, _breathingController]),
              builder: (context, child) {
                final loadingScale = _isLoading ? _scaleAnimation.value : 1.0;
                final breathingScale = isLit ? _breathingScale.value : 1.0;
                final totalScale = loadingScale * breathingScale;

                return SizedBox(
                  width: 154,
                  height: 154,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ambient outer pulse ring
                      if (isLit || _isLoading)
                        Transform.scale(
                          scale: totalScale,
                          child: Container(
                            width: 144,
                            height: 144,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.crimson.withValues(
                                alpha: _isLoading ? 0.25 : _breathingOpacity.value * 0.35,
                              ),
                            ),
                          ),
                        ),

                      // Outer gradient aura
                      if (isLit)
                        Container(
                          width: 136,
                          height: 136,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.crimson.withValues(alpha: 0.4),
                                blurRadius: 28 + (_isLoading ? _glowAnimation.value : 0),
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),

                      // Loading spinner
                      if (_isLoading)
                        const SizedBox(
                          width: 138,
                          height: 138,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.crimson),
                          ),
                        ),

                      // Center Circular Button
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isLit
                              ? const LinearGradient(
                                  colors: [Color(0xFFB61D46), Color(0xFF6B113B)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isLit ? null : Colors.white,
                          border: Border.all(
                            color: isLit
                                ? Colors.transparent
                                : AppTheme.roseGold.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isLit ? AppTheme.crimson : Colors.black)
                                  .withValues(alpha: isLit ? 0.35 : 0.05),
                              blurRadius: isLit ? 20 : 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 40,
                              color: isLit ? AppTheme.primaryFixed : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isLit ? 'Spark Lit' : 'Light My Spark',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: isLit ? Colors.white : AppTheme.plum,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              isLit ? 'Tap to soften' : 'Double-blind tap',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isLit ? AppTheme.primaryFixedDim : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Live Partner State Indicator & Breathing Effect
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isLit ? AppTheme.crimson : Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isLit
                      ? 'Your spark is lit · Waiting for $partnerName...'
                      : 'Your spark is unlit · $partnerName is unaware',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.plum,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Hidden until match sub-indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.visibility_off_rounded, size: 14, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7)),
              const SizedBox(width: 5),
              Text(
                '$partnerName\'s status: Hidden until match',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 100% Double-Blind Promise Capsule
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.blush),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_user_rounded, color: AppTheme.crimson, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.9),
                        height: 1.35,
                      ),
                      children: const [
                        TextSpan(
                          text: '100% Double-Blind Promise: ',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.plum),
                        ),
                        TextSpan(
                          text: 'Neither partner knows the other lit their spark until ',
                        ),
                        TextSpan(
                          text: 'both',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.crimson),
                        ),
                        TextSpan(
                          text: ' do simultaneously.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
