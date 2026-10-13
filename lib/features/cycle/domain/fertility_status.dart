import 'package:flutter/material.dart';
import 'package:love_app/core/theme/app_theme.dart';

enum FertilityPhase {
  safe,
  caution,
  fertile,
  menstruating,
  unknown,
}

class DailyFertilityInfo {
  final DateTime date;
  final FertilityPhase phase;
  final int? dayOfCycle;
  final int cycleLength;
  final String title;
  final String recommendation;
  final String rationale;

  const DailyFertilityInfo({
    required this.date,
    required this.phase,
    required this.dayOfCycle,
    required this.cycleLength,
    required this.title,
    required this.recommendation,
    required this.rationale,
  });

  Color get color {
    switch (phase) {
      case FertilityPhase.safe:
        return AppTheme.safeGreen;
      case FertilityPhase.caution:
        return AppTheme.cautionAmber;
      case FertilityPhase.fertile:
        return AppTheme.fertileRed;
      case FertilityPhase.menstruating:
        return AppTheme.periodPurple;
      case FertilityPhase.unknown:
        return Colors.grey;
    }
  }

  Color get bgColor {
    switch (phase) {
      case FertilityPhase.safe:
        return AppTheme.safeGreenBg;
      case FertilityPhase.caution:
        return AppTheme.cautionAmberBg;
      case FertilityPhase.fertile:
        return AppTheme.fertileRedBg;
      case FertilityPhase.menstruating:
        return AppTheme.periodPurpleBg;
      case FertilityPhase.unknown:
        return Colors.grey.shade100;
    }
  }

  IconData get icon {
    switch (phase) {
      case FertilityPhase.safe:
        return Icons.check_circle_outline;
      case FertilityPhase.caution:
        return Icons.warning_amber_rounded;
      case FertilityPhase.fertile:
        return Icons.block;
      case FertilityPhase.menstruating:
        return Icons.water_drop;
      case FertilityPhase.unknown:
        return Icons.help_outline;
    }
  }
}
