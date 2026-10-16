import 'package:flutter_test/flutter_test.dart';
import 'package:love_app/features/cycle/domain/cycle_engine.dart';
import 'package:love_app/features/cycle/domain/fertility_status.dart';

void main() {
  group('CycleEngine Fertility Calculations', () {
    final basePeriodStart = DateTime.utc(2026, 10, 1);

    test('Returns unknown when no period start date is provided', () {
      final result = CycleEngine.calculateFertility(
        targetDate: DateTime.utc(2026, 10, 12),
        lastPeriodStartDate: null,
      );

      expect(result.phase, equals(FertilityPhase.unknown));
      expect(result.dayOfCycle, isNull);
    });

    test('Standard 28-day cycle: calculates correct phases', () {
      // Day 1 to 5: Menstruation
      final day1 = CycleEngine.calculateFertility(
        targetDate: basePeriodStart, // Oct 1 = Day 1
        lastPeriodStartDate: basePeriodStart,
        cycleLength: 28,
        periodLength: 5,
        safetyBufferDays: 2,
      );
      expect(day1.dayOfCycle, equals(1));
      expect(day1.phase, equals(FertilityPhase.menstruating));

      final day4 = CycleEngine.calculateFertility(
        targetDate: basePeriodStart.add(const Duration(days: 3)), // Oct 4 = Day 4
        lastPeriodStartDate: basePeriodStart,
        cycleLength: 28,
        periodLength: 5,
        safetyBufferDays: 2,
      );
      expect(day4.dayOfCycle, equals(4));
      expect(day4.phase, equals(FertilityPhase.menstruating));

      // Day 6: Pre-ovulatory Caution Buffer (absorbed into caution under Sensiplan 5-day rule to avoid 1-day safe trap)
      final day6 = CycleEngine.calculateFertility(
        targetDate: basePeriodStart.add(const Duration(days: 5)), // Oct 6 = Day 6
        lastPeriodStartDate: basePeriodStart,
        cycleLength: 28,
        periodLength: 5,
        safetyBufferDays: 2,
      );
      expect(day6.dayOfCycle, equals(6));
      expect(day6.phase, equals(FertilityPhase.caution));

      // Day 7: Pre-fertile Caution Buffer (ovulation is 14, core fertile starts at 9, buffer at 7)
      final day7 = CycleEngine.calculateFertility(
        targetDate: basePeriodStart.add(const Duration(days: 6)), // Oct 7 = Day 7
        lastPeriodStartDate: basePeriodStart,
        cycleLength: 28,
        periodLength: 5,
        safetyBufferDays: 2,
      );
      expect(day7.dayOfCycle, equals(7));
      expect(day7.phase, equals(FertilityPhase.caution));

      // Day 9: Core Fertile Window (sperm can survive 5 days until ovulation)
      final day9 = CycleEngine.calculateFertility(
        targetDate: basePeriodStart.add(const Duration(days: 8)), // Oct 9 = Day 9
        lastPeriodStartDate: basePeriodStart,
        cycleLength: 28,
        periodLength: 5,
        safetyBufferDays: 2,
      );
      expect(day9.dayOfCycle, equals(9));
      expect(day9.phase, equals(FertilityPhase.fertile));

      // Day 14: Ovulation Day (Peak Risk)
      final day14 = CycleEngine.calculateFertility(
        targetDate: basePeriodStart.add(const Duration(days: 13)), // Oct 14 = Day 14
        lastPeriodStartDate: basePeriodStart,
        cycleLength: 28,
        periodLength: 5,
        safetyBufferDays: 2,
      );
      expect(day14.dayOfCycle, equals(14));
      expect(day14.phase, equals(FertilityPhase.fertile));
      expect(day14.title, contains('Ovulation'));

      // Day 15: Post-ovulation Caution Buffer (egg viability / potential delayed ovulation)
      final day15 = CycleEngine.calculateFertility(
        targetDate: basePeriodStart.add(const Duration(days: 14)), // Oct 15 = Day 15
        lastPeriodStartDate: basePeriodStart,
        cycleLength: 28,
        periodLength: 5,
        safetyBufferDays: 2,
      );
      expect(day15.dayOfCycle, equals(15));
      expect(day15.phase, equals(FertilityPhase.caution));

      // Day 16: Post-ovulation Caution Buffer (+2 day delayed ovulation risk)
      final day16 = CycleEngine.calculateFertility(
        targetDate: basePeriodStart.add(const Duration(days: 15)), // Oct 16 = Day 16
        lastPeriodStartDate: basePeriodStart,
        cycleLength: 28,
        periodLength: 5,
        safetyBufferDays: 2,
      );
      expect(day16.dayOfCycle, equals(16));
      expect(day16.phase, equals(FertilityPhase.caution));

      // Day 17: Post-ovulation Caution Buffer (24h egg viability after Day 16 ovulation)
      final day17 = CycleEngine.calculateFertility(
        targetDate: basePeriodStart.add(const Duration(days: 16)), // Oct 17 = Day 17
        lastPeriodStartDate: basePeriodStart,
        cycleLength: 28,
        periodLength: 5,
        safetyBufferDays: 2,
      );
      expect(day17.dayOfCycle, equals(17));
      expect(day17.phase, equals(FertilityPhase.caution));

      // Day 18: Post-ovulation Safe Window begins (Verified Luteal Phase, egg dissolved)
      final day18 = CycleEngine.calculateFertility(
        targetDate: basePeriodStart.add(const Duration(days: 17)), // Oct 18 = Day 18
        lastPeriodStartDate: basePeriodStart,
        cycleLength: 28,
        periodLength: 5,
        safetyBufferDays: 2,
      );
      expect(day18.dayOfCycle, equals(18));
      expect(day18.phase, equals(FertilityPhase.safe));
      expect(day18.recommendation, contains('Lowest probability of pregnancy'));

      // Day 28: End of cycle safe window
      final day28 = CycleEngine.calculateFertility(
        targetDate: basePeriodStart.add(const Duration(days: 27)), // Oct 28 = Day 28
        lastPeriodStartDate: basePeriodStart,
        cycleLength: 28,
        periodLength: 5,
        safetyBufferDays: 2,
      );
      expect(day28.dayOfCycle, equals(28));
      expect(day28.phase, equals(FertilityPhase.safe));
    });

    test('Short 24-day cycle: safely flags early fertile overlap', () {
      final shortStart = DateTime.utc(2026, 10, 1);
      // For 24-day cycle, ovulation is day 10. Core fertile is days 5-11. Buffer starts day 3.
      // Day 4 is menstruation, but overlaps with fertile buffer!
      final day4 = CycleEngine.calculateFertility(
        targetDate: shortStart.add(const Duration(days: 3)), // Day 4
        lastPeriodStartDate: shortStart,
        cycleLength: 24,
        periodLength: 5,
        safetyBufferDays: 2,
      );
      expect(day4.phase, equals(FertilityPhase.caution));
      expect(day4.title, contains('Period + Fertile Buffer'));
    });

    test('31-day cycle: Days 6, 7, 8 after menstruation are classified as Pre-Ovulation Caution Buffer', () {
      // In a 31-day cycle with 5-day period:
      // Menstruation: Days 1-5
      // Pre-ovulation Caution Buffer: Days 6-11 (including Day 8)
      // Core Fertile: Days 12-17 (Ovulation on Day 17)
      for (final dayIndex in [5, 6, 7]) { // Days 6, 7, 8 (0-indexed offset 5, 6, 7)
        final info = CycleEngine.calculateFertility(
          targetDate: basePeriodStart.add(Duration(days: dayIndex)),
          lastPeriodStartDate: basePeriodStart,
          cycleLength: 31,
          periodLength: 5,
          safetyBufferDays: 3,
        );
        expect(info.dayOfCycle, equals(dayIndex + 1));
        expect(info.phase, equals(FertilityPhase.caution));
        expect(info.title, contains('Caution / Pre-Ovulation Buffer'));
      }
    });

    test('Safety buffer clamping: cannot go below 2 days', () {
      // Even if safetyBufferDays = 0 or 1 is passed, it must clamp to 2
      final day17WithBuffer1 = CycleEngine.calculateFertility(
        targetDate: basePeriodStart.add(const Duration(days: 16)), // Day 17
        lastPeriodStartDate: basePeriodStart,
        cycleLength: 28,
        periodLength: 5,
        safetyBufferDays: 1, // Attempt to set 1 day
      );
      // With effective buffer 2: Day 17 is still caution!
      expect(day17WithBuffer1.phase, equals(FertilityPhase.caution));

      final day6WithBuffer0 = CycleEngine.calculateFertility(
        targetDate: basePeriodStart.add(const Duration(days: 5)), // Day 6
        lastPeriodStartDate: basePeriodStart,
        cycleLength: 28,
        periodLength: 5,
        safetyBufferDays: 0, // Attempt to set 0 days
      );
      expect(day6WithBuffer0.phase, equals(FertilityPhase.caution));
    });

    test('getNextDayBeforeCycleStarts calculates 1 day before next cycle Day 1', () {
      final now = DateTime(2026, 10, 16, 9, 0); // Day 16 of cycle starting Oct 1
      final nextCycleNotice = CycleEngine.getNextDayBeforeCycleStarts(
        fromDate: now,
        lastPeriodStartDate: basePeriodStart,
        cycleLength: 28,
        notificationHour: 10,
        notificationMinute: 0,
      );

      // Cycle 1: Oct 1 to Oct 28. Next cycle starts Oct 29.
      // Day before next cycle begins is Oct 28 at 10:00 AM!
      expect(nextCycleNotice, isNotNull);
      expect(nextCycleNotice!.year, equals(2026));
      expect(nextCycleNotice.month, equals(10));
      expect(nextCycleNotice.day, equals(28));
      expect(nextCycleNotice.hour, equals(10));
    });

    test('getNextDayBeforeSafeWindowStarts calculates Day bufferEnd (Day 17 for 28d cycle)', () {
      final now = DateTime(2026, 10, 15, 9, 0); // Day 15 of cycle starting Oct 1
      final safeWindowNotice = CycleEngine.getNextDayBeforeSafeWindowStarts(
        fromDate: now,
        lastPeriodStartDate: basePeriodStart,
        cycleLength: 28,
        safetyBufferDays: 2,
        notificationHour: 10,
        notificationMinute: 0,
      );

      // BufferEnd for 28-day cycle with buffer 2 is Day 17 (Oct 17).
      // Safe window starts Day 18 (Oct 18).
      // Day before safe window is Day 17 (Oct 17) at 10:00 AM.
      expect(safeWindowNotice, isNotNull);
      expect(safeWindowNotice!.year, equals(2026));
      expect(safeWindowNotice.month, equals(10));
      expect(safeWindowNotice.day, equals(17));
      expect(safeWindowNotice.hour, equals(10));
    });

    test('getNextDayBeforeSafeWindowStarts rolls over to next cycle if already past in current', () {
      final now = DateTime(2026, 10, 20, 12, 0); // Day 20 (already past Day 17)
      final safeWindowNotice = CycleEngine.getNextDayBeforeSafeWindowStarts(
        fromDate: now,
        lastPeriodStartDate: basePeriodStart,
        cycleLength: 28,
        safetyBufferDays: 2,
        notificationHour: 10,
        notificationMinute: 0,
      );

      // Current cycle's Day 17 was Oct 17.
      // Next cycle starts Oct 29. Next Day 17 is Oct 29 + 16 days = Nov 14!
      expect(safeWindowNotice, isNotNull);
      expect(safeWindowNotice!.year, equals(2026));
      expect(safeWindowNotice.month, equals(11));
      expect(safeWindowNotice.day, equals(14));
      expect(safeWindowNotice.hour, equals(10));
    });
  });
}
