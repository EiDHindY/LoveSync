import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/cycle/domain/cycle_engine.dart';
import 'package:love_app/features/cycle/domain/fertility_status.dart';

class FertilityDial extends StatelessWidget {
  final DailyFertilityInfo fertilityInfo;
  final VoidCallback onLogPeriod;
  final bool canLog;
  final String? managerName;
  final DateTime? lastPeriodStartDate;
  final int cycleLength;
  final int periodLength;
  final int safetyBufferDays;

  const FertilityDial({
    super.key,
    required this.fertilityInfo,
    required this.onLogPeriod,
    this.canLog = true,
    this.managerName,
    this.lastPeriodStartDate,
    this.cycleLength = 28,
    this.periodLength = 5,
    this.safetyBufferDays = 2,
  });

  @override
  Widget build(BuildContext context) {
    final day = fertilityInfo.dayOfCycle;
    final total = cycleLength;

    // Calculate ovulation forecast
    final daysUntilOvulation = CycleEngine.getDaysUntilOvulation(
      targetDate: fertilityInfo.date,
      lastPeriodStartDate: lastPeriodStartDate,
      cycleLength: total,
    );
    final ovulationDate = CycleEngine.getNextOvulationDate(
      targetDate: fertilityInfo.date,
      lastPeriodStartDate: lastPeriodStartDate,
      cycleLength: total,
    );

    // Compute cycle phase boundaries for segmented ring
    final ovulationDay = total - 14;
    final coreFertileStart = ovulationDay - 5;
    final coreFertileEnd = ovulationDay;
    final effectiveBuffer = safetyBufferDays < 2 ? 2 : safetyBufferDays;
    final bufferStart = periodLength + 1;
    final bufferEnd = (ovulationDay + effectiveBuffer) + 1;

    // Pill badge colors & label
    final (badgeBg, badgeBorder, badgeText, badgeLabel, indicatorColor) = _resolveBadgeDetails(fertilityInfo);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B113B).withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF2C0E28).withValues(alpha: 0.06),
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Atmospheric Glows
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withValues(alpha: 0.08),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6B113B).withValues(alpha: 0.05),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),

            // Main Card Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  if (!canLog && managerName != null && managerName!.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.blush.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: AppTheme.roseGold.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sync_rounded, size: 14, color: AppTheme.crimson),
                          const SizedBox(width: 5),
                          Text(
                            'Viewing $managerName\'s Cycle (Live Sync)',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.crimson,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Circular Segmented Ring Dial
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(240, 240),
                          painter: _SegmentedCyclePainter(
                            cycleLength: total,
                            periodLength: periodLength,
                            bufferStart: bufferStart,
                            coreFertileStart: coreFertileStart,
                            coreFertileEnd: coreFertileEnd,
                            bufferEnd: bufferEnd,
                            dayOfCycle: day,
                            indicatorColor: indicatorColor,
                          ),
                        ),
                        // Center Information
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              !canLog && managerName != null && managerName!.isNotEmpty
                                  ? '${managerName!.toUpperCase()}\'S RHYTHM'
                                  : 'NATURAL RHYTHM',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              day != null ? 'Day $day' : 'No Data',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.plum,
                                letterSpacing: -0.6,
                              ),
                            ),
                            Text(
                              'of $total-Day Cycle',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Inside Status Pill Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(9999),
                                border: Border.all(color: badgeBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: badgeText.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: indicatorColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    badgeLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: badgeText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Micro Detail Forecast Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.upcoming_rounded,
                          size: 16,
                          color: AppTheme.crimson,
                        ),
                        const SizedBox(width: 6),
                        if (daysUntilOvulation != null && ovulationDate != null)
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.95),
                                fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                              ),
                              children: [
                                const TextSpan(text: 'Ovulation predicted in '),
                                TextSpan(
                                  text: daysUntilOvulation == 0
                                      ? 'today'
                                      : '~$daysUntilOvulation days',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.crimson,
                                  ),
                                ),
                                TextSpan(
                                  text: ' (${DateFormat('MMM d').format(ovulationDate)})',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            'Log period start date to forecast ovulation',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cycle Legend Key
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      _buildLegendItem(const Color(0xFFC084FC), 'Menses'),
                      _buildLegendItem(const Color(0xFF10B981), 'Low Risk'),
                      _buildLegendItem(const Color(0xFFF59E0B), 'Buffer'),
                      _buildLegendItem(const Color(0xFFFE5678), 'Peak Fertile'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  (Color, Color, Color, String, Color) _resolveBadgeDetails(DailyFertilityInfo info) {
    switch (info.phase) {
      case FertilityPhase.safe:
        return (
          const Color(0xFFECFDF5),
          const Color(0xFFA7F3D0),
          const Color(0xFF065F46),
          'Safe Window',
          const Color(0xFF10B981),
        );
      case FertilityPhase.caution:
        return (
          const Color(0xFFFEF3C7),
          const Color(0xFFFDE68A),
          const Color(0xFF92400E),
          'Caution Buffer',
          const Color(0xFFF59E0B),
        );
      case FertilityPhase.fertile:
        final isOvulation = info.title.toLowerCase().contains('ovulation');
        return (
          const Color(0xFFFEE2E2),
          const Color(0xFFFECACA),
          const Color(0xFF991B1B),
          isOvulation ? 'Ovulation Peak' : 'Peak Fertile',
          const Color(0xFFFE5678),
        );
      case FertilityPhase.menstruating:
        return (
          const Color(0xFFF3E8FF),
          const Color(0xFFDDD6FE),
          const Color(0xFF6B21A8),
          'Period Active',
          const Color(0xFFC084FC),
        );
      case FertilityPhase.unknown:
        return (
          const Color(0xFFF3F4F6),
          const Color(0xFFE5E7EB),
          const Color(0xFF4B5563),
          'No Cycle Data',
          Colors.grey,
        );
    }
  }
}

/// Custom painter for rendering the beautiful 28-day segmented circular dial
class _SegmentedCyclePainter extends CustomPainter {
  final int cycleLength;
  final int periodLength;
  final int bufferStart;
  final int coreFertileStart;
  final int coreFertileEnd;
  final int bufferEnd;
  final int? dayOfCycle;
  final Color indicatorColor;

  _SegmentedCyclePainter({
    required this.cycleLength,
    required this.periodLength,
    required this.bufferStart,
    required this.coreFertileStart,
    required this.coreFertileEnd,
    required this.bufferEnd,
    required this.dayOfCycle,
    required this.indicatorColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = 13.0;
    final radius = (size.width - strokeWidth) / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Background Track (Soft Pinkish Lavender)
    final bgPaint = Paint()
      ..color = const Color(0xFFFFDFF4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, bgPaint);

    if (cycleLength <= 0) return;

    void drawSegment({
      required int startDay,
      required int endDay,
      required Color color,
      double width = 13.0,
      double opacity = 1.0,
    }) {
      if (endDay < startDay) return;
      final startRatio = (startDay - 1) / cycleLength;
      final sweepRatio = (endDay - startDay + 1) / cycleLength;

      final baseStartAngle = -math.pi / 2 + (startRatio * 2 * math.pi);
      final baseSweepAngle = (sweepRatio * 2 * math.pi);

      // Margin accounting for StrokeCap.round extent so adjacent arcs do not touch/bleed
      final capRadiusAngle = (width / 2) / radius;
      final marginAngle = capRadiusAngle + 0.022;

      final actualStart = baseStartAngle + marginAngle;
      final actualSweep = baseSweepAngle - (marginAngle * 2);

      if (actualSweep <= 0.02) return;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        actualStart,
        actualSweep,
        false,
        paint,
      );
    }

    // Segment 1: Menses (Lavender: Days 1 to periodLength)
    drawSegment(
      startDay: 1,
      endDay: periodLength,
      color: const Color(0xFFC084FC),
      width: 13.0,
      opacity: 0.95,
    );

    // Segment 2: Caution Buffer (Pre-ovulation: Days bufferStart to coreFertileStart - 1)
    if (coreFertileStart > bufferStart) {
      drawSegment(
        startDay: bufferStart,
        endDay: coreFertileStart - 1,
        color: const Color(0xFFF59E0B),
        width: 13.0,
        opacity: 0.95,
      );
    }

    // Segment 4: Peak Fertile / Ovulation (Days coreFertileStart to coreFertileEnd)
    drawSegment(
      startDay: coreFertileStart,
      endDay: coreFertileEnd,
      color: const Color(0xFFFE5678),
      width: 13.0,
      opacity: 1.0,
    );

    // Segment 5: Post-fertile Caution Buffer (Days coreFertileEnd + 1 to bufferEnd)
    if (bufferEnd > coreFertileEnd) {
      drawSegment(
        startDay: coreFertileEnd + 1,
        endDay: bufferEnd,
        color: const Color(0xFFF59E0B),
        width: 13.0,
        opacity: 0.95,
      );
    }

    // Segment 6: Luteal Safe Phase (Days bufferEnd + 1 to cycleLength)
    if (cycleLength > bufferEnd) {
      drawSegment(
        startDay: bufferEnd + 1,
        endDay: cycleLength,
        color: const Color(0xFF10B981),
        width: 13.0,
        opacity: 0.9,
      );
    }

    // Draw Ovulation Marker Target at Day 14 (or ovulationDay)
    final ovulationDay = cycleLength - 14;
    final ovRatio = (ovulationDay - 0.5) / cycleLength;
    final ovAngle = -math.pi / 2 + (ovRatio * 2 * math.pi);
    final ovCenter = Offset(
      center.dx + radius * math.cos(ovAngle),
      center.dy + radius * math.sin(ovAngle),
    );

    // 1. Ovulation Target Backdrop with drop shadow
    final ovShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(ovCenter.translate(0, 1), 10, ovShadowPaint);

    final ovBgPaint = Paint()
      ..color = const Color(0xFF2C0E28)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(ovCenter, 9.5, ovBgPaint);

    final ovRingPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(ovCenter, 9.5, ovRingPaint);

    final ovDotPaint = Paint()
      ..color = const Color(0xFFFE5678)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(ovCenter, 3.6, ovDotPaint);

    // 4 Directional Arrows pointing at Ovulation Center
    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Top arrow
    final topPath = Path()
      ..moveTo(ovCenter.dx, ovCenter.dy - 6.5)
      ..lineTo(ovCenter.dx - 2.5, ovCenter.dy - 11.0)
      ..lineTo(ovCenter.dx + 2.5, ovCenter.dy - 11.0)
      ..close();
    canvas.drawPath(topPath, arrowPaint);

    // Bottom arrow
    final bottomPath = Path()
      ..moveTo(ovCenter.dx, ovCenter.dy + 6.5)
      ..lineTo(ovCenter.dx - 2.5, ovCenter.dy + 11.0)
      ..lineTo(ovCenter.dx + 2.5, ovCenter.dy + 11.0)
      ..close();
    canvas.drawPath(bottomPath, arrowPaint);

    // Left arrow
    final leftPath = Path()
      ..moveTo(ovCenter.dx - 6.5, ovCenter.dy)
      ..lineTo(ovCenter.dx - 11.0, ovCenter.dy - 2.5)
      ..lineTo(ovCenter.dx - 11.0, ovCenter.dy + 2.5)
      ..close();
    canvas.drawPath(leftPath, arrowPaint);

    // Right arrow
    final rightPath = Path()
      ..moveTo(ovCenter.dx + 6.5, ovCenter.dy)
      ..lineTo(ovCenter.dx + 11.0, ovCenter.dy - 2.5)
      ..lineTo(ovCenter.dx + 11.0, ovCenter.dy + 2.5)
      ..close();
    canvas.drawPath(rightPath, arrowPaint);

    // Current Day Needle Indicator
    if (dayOfCycle != null && dayOfCycle! >= 1 && dayOfCycle! <= cycleLength) {
      final needleRatio = (dayOfCycle! - 0.5) / cycleLength;
      final needleAngle = -math.pi / 2 + (needleRatio * 2 * math.pi);
      final cx = center.dx + radius * math.cos(needleAngle);
      final cy = center.dy + radius * math.sin(needleAngle);
      final indicatorPos = Offset(cx, cy);

      // Outer soft glow
      final glowPaint = Paint()
        ..color = indicatorColor.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(indicatorPos, 14, glowPaint);

      // White solid dot
      final innerWhite = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(indicatorPos, 9.0, innerWhite);

      // Outer colored stroke
      final strokePaint = Paint()
        ..color = indicatorColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;
      canvas.drawCircle(indicatorPos, 9.0, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedCyclePainter oldDelegate) {
    return oldDelegate.cycleLength != cycleLength ||
        oldDelegate.periodLength != periodLength ||
        oldDelegate.bufferStart != bufferStart ||
        oldDelegate.coreFertileStart != coreFertileStart ||
        oldDelegate.coreFertileEnd != coreFertileEnd ||
        oldDelegate.bufferEnd != bufferEnd ||
        oldDelegate.dayOfCycle != dayOfCycle ||
        oldDelegate.indicatorColor != indicatorColor;
  }
}
