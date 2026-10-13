import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/cycle/domain/cycle_engine.dart';

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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.blush, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny_outlined, size: 16, color: AppTheme.crimson),
              const SizedBox(width: 6),
              Text(
                '7-DAY SAFETY FORECAST',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: AppTheme.plum.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((date) {
              final isToday = date.day == now.day && date.month == now.month;
              final fertility = CycleEngine.calculateFertility(
                targetDate: date,
                lastPeriodStartDate: lastPeriodStartDate,
                cycleLength: cycleLength,
                periodLength: periodLength,
                safetyBufferDays: safetyBufferDays,
              );

              final dayLetter = DateFormat('E').format(date).substring(0, 1);
              final dayNum = date.day.toString();

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: isToday ? AppTheme.blush.withValues(alpha: 0.5) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isToday
                      ? Border.all(color: AppTheme.roseGold.withValues(alpha: 0.6), width: 1.2)
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      dayLetter,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                        color: isToday ? AppTheme.crimson : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayNum,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isToday ? AppTheme.plum : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: fertility.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
