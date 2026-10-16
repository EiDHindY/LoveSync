import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/cycle/domain/cycle_engine.dart';
import 'package:love_app/features/cycle/domain/fertility_status.dart';

class CycleForecastBar extends StatelessWidget {
  final DateTime? lastPeriodStartDate;
  final int cycleLength;
  final int periodLength;
  final int safetyBufferDays;

  const CycleForecastBar({
    super.key,
    required this.lastPeriodStartDate,
    required this.cycleLength,
    required this.periodLength,
    required this.safetyBufferDays,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (index) => now.add(Duration(days: index)));
    final ovulationDay = CycleEngine.getOvulationDay(cycleLength);

    final startRangeStr = DateFormat('MMM d').format(days.first);
    final endRangeStr = DateFormat('d').format(days.last);
    final rangeLabel = '$startRangeStr – $endRangeStr';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.date_range_rounded,
                  size: 20,
                  color: AppTheme.crimson,
                ),
                const SizedBox(width: 8),
                const Text(
                  '7-Day Safety Forecast',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.plum,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            Text(
              rangeLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Plan spontaneous weekend date nights and shared safety at a glance.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),

        // Horizontal Daily Forecast Strip
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: days.asMap().entries.map((entry) {
              final index = entry.key;
              final date = entry.value;
              final isToday = index == 0;

              final fertility = CycleEngine.calculateFertility(
                targetDate: date,
                lastPeriodStartDate: lastPeriodStartDate,
                cycleLength: cycleLength,
                periodLength: periodLength,
                safetyBufferDays: safetyBufferDays,
              );

              final dayOfCycle = fertility.dayOfCycle;
              final isOvulationDay = dayOfCycle != null && dayOfCycle == ovulationDay;

              return Padding(
                padding: EdgeInsets.only(
                  right: index == days.length - 1 ? 0 : 10,
                ),
                child: _buildDayCard(
                  context: context,
                  date: date,
                  fertility: fertility,
                  isToday: isToday,
                  isOvulationDay: isOvulationDay,
                  ovulationDay: ovulationDay,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard({
    required BuildContext context,
    required DateTime date,
    required DailyFertilityInfo fertility,
    required bool isToday,
    required bool isOvulationDay,
    required int ovulationDay,
  }) {
    final dayOfWeekStr = DateFormat('E d').format(date);
    final dayNum = fertility.dayOfCycle;

    // Special Highlight for Ovulation Day
    if (isOvulationDay) {
      return Container(
        width: 104,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryFixed,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFFE5678).withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B113B).withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isToday)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: const Text(
                  'TODAY',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
              )
            else
              const SizedBox(height: 16),
            Text(
              dayOfWeekStr,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3E001E),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dayNum != null ? 'D$dayNum' : '--',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E001E),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.adjust_rounded,
                  size: 18,
                  color: AppTheme.crimson,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ovulation',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E001E),
              ),
            ),
            const SizedBox(height: 1),
            const Text(
              'Highest risk',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF7F234B),
              ),
            ),
          ],
        ),
      );
    }

    // Standard Days (Safe, Caution, Fertile, Period)
    final (badgeBg, dotColor, statusLabel, subLabel) = _resolveDayDetails(fertility, ovulationDay);

    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF2C0E28).withValues(alpha: 0.06),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B113B).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isToday)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: const Text(
                'TODAY',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.6,
                ),
              ),
            )
          else
            const SizedBox(height: 16),
          Text(
            dayOfWeekStr,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dayNum != null ? 'D$dayNum' : '--',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppTheme.plum,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: badgeBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: dotColor == const Color(0xFF10B981)
                  ? const Color(0xFF065F46)
                  : dotColor == const Color(0xFFF59E0B)
                      ? const Color(0xFF92400E)
                      : dotColor == const Color(0xFFFE5678)
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFF6B21A8),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subLabel,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, String, String) _resolveDayDetails(
    DailyFertilityInfo fertility,
    int ovulationDay,
  ) {
    final dayNum = fertility.dayOfCycle;
    switch (fertility.phase) {
      case FertilityPhase.safe:
        return (
          const Color(0xFFE8F5E9),
          const Color(0xFF10B981),
          'Safe',
          'Low Risk',
        );
      case FertilityPhase.caution:
        final sub = (dayNum != null && dayNum < ovulationDay)
            ? 'Sperm buffer'
            : 'Fertile buffer';
        return (
          const Color(0xFFFEF3C7),
          const Color(0xFFF59E0B),
          'Caution',
          sub,
        );
      case FertilityPhase.fertile:
        final sub = (dayNum != null && dayNum < ovulationDay)
            ? 'High risk'
            : 'Egg viable';
        return (
          const Color(0xFFFEE2E2),
          const Color(0xFFFE5678),
          'Peak Fertile',
          sub,
        );
      case FertilityPhase.menstruating:
        return (
          const Color(0xFFEDE9FE),
          const Color(0xFFC084FC),
          'Period',
          'Menses',
        );
      case FertilityPhase.unknown:
        return (
          const Color(0xFFF3F4F6),
          Colors.grey,
          'Unknown',
          'No Data',
        );
    }
  }
}
