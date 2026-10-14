import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/mood/domain/mood_status.dart';

class SparkButton extends StatefulWidget {
  final MoodStatus moodStatus;
  final FutureOr<void> Function() onToggle;

  const SparkButton({
    super.key,
    required this.moodStatus,
    required this.onToggle,
  });

  @override
  State<SparkButton> createState() => _SparkButtonState();
}

class _SparkButtonState extends State<SparkButton>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  Timer? _countdownTimer;
  bool _previousMatch = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _previousMatch = widget.moodStatus.isMatch;
    if (_previousMatch) {
      _confettiController.play();
    }
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 6.0, end: 22.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
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
      return 'Light goes off at $targetTimeStr ($remainingStr)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMatch = widget.moodStatus.isMatch;
    final isLit = widget.moodStatus.userInTheMood;
    final shifted = DateTime.now().subtract(const Duration(hours: 4));
    final isDay = shifted.hour < 12;
    final timeLabel = isDay ? 'Today' : 'Tonight';
    final windowLabel = isDay ? 'DAY SPARK • 4AM - 4PM' : 'NIGHT SPARK • 4PM - 4AM';

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
            ],
          ),
        ),

        // Main Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: isMatch
                ? const LinearGradient(
                    colors: [Color(0xFF6B113B), Color(0xFFC0264D), Color(0xFFE2847A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : isLit
                    ? LinearGradient(
                        colors: [
                          AppTheme.plum.withValues(alpha: 0.9),
                          AppTheme.deepBerry,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
            color: (isMatch || isLit) ? null : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isMatch
                  ? AppTheme.crimson
                  : isLit
                      ? AppTheme.roseGold.withValues(alpha: 0.6)
                      : AppTheme.blush,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isMatch ? AppTheme.crimson : AppTheme.plum).withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isMatch
                        ? Icons.local_fire_department
                        : isLit
                            ? Icons.flare
                            : (isDay ? Icons.wb_sunny_rounded : Icons.favorite_border),
                    color: (isMatch || isLit) ? Colors.white : AppTheme.crimson,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    windowLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: (isMatch || isLit) ? Colors.white.withValues(alpha: 0.9) : AppTheme.plum.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Animated Spark Button Icon
              GestureDetector(
                onTap: _isLoading ? null : _handleToggle,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = _isLoading ? _scaleAnimation.value : 1.0;
                    final extraGlow = _isLoading ? _glowAnimation.value : 0.0;

                    return Transform.scale(
                      scale: scale,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isLoading)
                            SizedBox(
                              width: 104,
                              height: 104,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isMatch || isLit ? Colors.white : AppTheme.crimson,
                                ),
                              ),
                            ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isMatch
                                  ? const RadialGradient(
                                      colors: [Color(0xFFFFDF7D), Color(0xFFFF4081), Color(0xFFC0264D)],
                                    )
                                  : isLit
                                      ? const RadialGradient(
                                          colors: [Color(0xFFFF8A80), Color(0xFFC0264D)],
                                        )
                                      : (_isLoading
                                          ? const RadialGradient(
                                              colors: [Color(0xFFFF8A80), Color(0xFFC0264D)],
                                            )
                                          : null),
                              color: (!isMatch && !isLit && !_isLoading) ? AppTheme.blush : null,
                              boxShadow: [
                                BoxShadow(
                                  color: (isMatch || isLit || _isLoading
                                          ? AppTheme.crimson
                                          : AppTheme.roseGold)
                                      .withValues(alpha: 0.5),
                                  blurRadius: (isMatch ? 28 : (isLit ? 16 : 8)) + extraGlow,
                                  spreadRadius: (isMatch ? 4 : (isLit ? 2 : 0)) + (_isLoading ? 2 : 0),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isLoading
                                  ? Icon(
                                      isLit ? Icons.power_settings_new_rounded : Icons.local_fire_department_rounded,
                                      size: 46,
                                      color: Colors.white,
                                    )
                                  : Icon(
                                      isMatch
                                          ? Icons.local_fire_department_rounded
                                          : isLit
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_outline_rounded,
                                      size: 46,
                                      color: (isMatch || isLit) ? Colors.white : AppTheme.crimson,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Status Title
              Text(
                _isLoading
                    ? (isLit ? 'Turning off spark... ✨' : 'Lighting your spark... 🔥')
                    : isMatch
                        ? "IT'S A MATCH! 🔥"
                        : isLit
                            ? 'Your Spark is Lit ✨'
                            : 'In the mood $timeLabel?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: (isMatch || isLit || _isLoading) ? Colors.white : AppTheme.plum,
                ),
              ),

              // Expiry / Duration Badge (Active until 4:00 AM / 4:00 PM)
              if (isLit || isMatch) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        _formatRemainingTime(DateTime.now(), isMatch),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 6),

              // Explanation / Zero-Knowledge Guarantee
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  isMatch
                      ? "Both of you secretly tapped in the mood! The spark is ignited for $timeLabel."
                      : isLit
                          ? "Your desire is logged privately. Your partner has NO IDEA unless they also tap."
                          : "Tap if you're feeling romantic. If your partner doesn't tap, they will never know.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: (isMatch || isLit)
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMatch
                        ? Colors.white
                        : isLit
                            ? AppTheme.blush.withValues(alpha: 0.3)
                            : AppTheme.deepBerry,
                    foregroundColor: isMatch
                        ? AppTheme.crimson
                        : isLit
                            ? Colors.white
                            : Colors.white,
                    elevation: isMatch ? 4 : 1,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isLoading ? null : _handleToggle,
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isMatch ? AppTheme.crimson : Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isLit ? 'Updating spark...' : 'Igniting your spark... ✨',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isMatch ? AppTheme.crimson : Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          isMatch
                              ? 'Celebrate! 🎉 (Tap to turn off)'
                              : isLit
                                  ? 'Turn Off Spark'
                                  : 'Light My Spark for $timeLabel',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isMatch ? AppTheme.crimson : Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
