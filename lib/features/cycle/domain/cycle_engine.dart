import 'package:love_app/features/cycle/domain/fertility_status.dart';

class CycleEngine {
  /// Pure function to calculate fertility status for any given date
  static DailyFertilityInfo calculateFertility({
    required DateTime targetDate,
    required DateTime? lastPeriodStartDate,
    int cycleLength = 28,
    int periodLength = 5,
    int safetyBufferDays = 2,
  }) {
    if (lastPeriodStartDate == null) {
      return DailyFertilityInfo(
        date: targetDate,
        phase: FertilityPhase.unknown,
        dayOfCycle: null,
        cycleLength: cycleLength,
        title: 'No Cycle Data',
        recommendation: 'Log your last period to calculate safe & fertile days.',
        rationale: 'Fertility awareness requires at least the last period start date.',
      );
    }

    // Normalize dates to midnight UTC to prevent daylight savings skew
    final start = DateTime.utc(
      lastPeriodStartDate.year,
      lastPeriodStartDate.month,
      lastPeriodStartDate.day,
    );
    final target = DateTime.utc(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

    final daysDifference = target.difference(start).inDays;

    // Handle modulo for past or future cycles
    final cycleIndex = (daysDifference % cycleLength + cycleLength) % cycleLength;
    final dayOfCycle = cycleIndex + 1; // 1-indexed (Day 1 to cycleLength)

    // Standard clinical estimation: Ovulation occurs ~14 days before the end of the cycle
    final ovulationDay = cycleLength - 14;

    // Minimum buffer is 2 days (users cannot go below 2 days for safety)
    final effectiveBuffer = safetyBufferDays < 2 ? 2 : safetyBufferDays;

    // Viable sperm window: up to 5 days before ovulation (Zone 4: [E[O] - 5, E[O]])
    final coreFertileStart = ovulationDay - 5;
    final coreFertileEnd = ovulationDay;

    // Safety buffer boundaries:
    // Pre-ovulatory caution extends immediately from the end of menstruation (periodLength + 1)
    // to the start of the core fertile window. Any intercourse after menstruation carries real pregnancy
    // risk because sperm survives up to 5 days and ovulation timing can shift earlier than expected.
    final bufferStart = periodLength + 1;

    // Right-tail: Guards against delayed ovulation (E[O] + effectiveBuffer) + 24h (1 day) oocyte viability
    final bufferEnd = (ovulationDay + effectiveBuffer) + 1;

    // Check Menstruation first
    if (dayOfCycle >= 1 && dayOfCycle <= periodLength) {
      // If cycle is unusually short, period might overlap with fertile buffer
      final effectiveFertileBufferStart = (ovulationDay - effectiveBuffer) - 5;
      if (dayOfCycle >= coreFertileStart || dayOfCycle >= effectiveFertileBufferStart) {
        return DailyFertilityInfo(
          date: targetDate,
          phase: FertilityPhase.caution,
          dayOfCycle: dayOfCycle,
          cycleLength: cycleLength,
          title: 'Period + Fertile Buffer',
          recommendation: 'Menstruation active, but approaching early fertile window due to cycle length.',
          rationale: 'In shorter cycles, sperm can survive past bleeding until early ovulation.',
        );
      }
      return DailyFertilityInfo(
        date: targetDate,
        phase: FertilityPhase.menstruating,
        dayOfCycle: dayOfCycle,
        cycleLength: cycleLength,
        title: 'Period Active (Day $dayOfCycle)',
        recommendation: 'Active menstrual bleeding. Very low conception risk for standard 28+ day cycles.',
        rationale: 'Uterine lining is actively shedding; ovulation is still distant.',
      );
    }

    // Check Peak Fertile Window
    if (dayOfCycle >= coreFertileStart && dayOfCycle <= coreFertileEnd) {
      final isOvulationDay = dayOfCycle == ovulationDay;
      return DailyFertilityInfo(
        date: targetDate,
        phase: FertilityPhase.fertile,
        dayOfCycle: dayOfCycle,
        cycleLength: cycleLength,
        title: isOvulationDay
            ? 'Ovulation Day (Peak Risk) 🔥'
            : 'High Pregnancy Risk (Fertile)',
        recommendation:
            'Do NOT ejaculate inside if avoiding pregnancy. Conception probability is highest today.',
        rationale:
            'Sperm can survive up to 5 days and the ovum is either releasing or currently viable.',
      );
    }

    // Check Caution / Buffer Window
    if ((dayOfCycle >= bufferStart && dayOfCycle < coreFertileStart) ||
        (dayOfCycle > coreFertileEnd && dayOfCycle <= bufferEnd)) {
      final isPreOvulation = dayOfCycle < coreFertileStart;
      return DailyFertilityInfo(
        date: targetDate,
        phase: FertilityPhase.caution,
        dayOfCycle: dayOfCycle,
        cycleLength: cycleLength,
        title: isPreOvulation
            ? 'Caution / Pre-Ovulation Buffer'
            : 'Caution / Post-Ovulation Buffer',
        recommendation:
            'Buffer zone. Protected sex (condom/withdrawal) strongly recommended.',
        rationale: isPreOvulation
            ? 'Pre-ovulation phase: ovulation can arrive early; sperm can survive up to 5 days.'
            : 'Ovulation can be delayed up to $effectiveBuffer days, plus up to 24 hours of ovum viability.',
      );
    }

    // Safe Window (Post-Ovulation Luteal Phase)
    return DailyFertilityInfo(
      date: targetDate,
      phase: FertilityPhase.safe,
      dayOfCycle: dayOfCycle,
      cycleLength: cycleLength,
      title: 'Safe Window (Post-Ovulation)',
      recommendation:
          'Lowest probability of pregnancy. Safe for unprotected ejaculation if cycle is regular.',
      rationale:
          'Egg has dissolved for this cycle; next ovulation cannot occur until the following cycle.',
    );
  }

  /// Estimated ovulation day within the cycle (typically 14 days before next cycle)
  static int getOvulationDay(int cycleLength) => cycleLength - 14;

  /// Calculate the current 1-indexed day of the cycle for a given date
  static int? getCurrentCycleDay({
    required DateTime targetDate,
    required DateTime? lastPeriodStartDate,
    int cycleLength = 28,
  }) {
    if (lastPeriodStartDate == null) return null;
    final start = DateTime.utc(
      lastPeriodStartDate.year,
      lastPeriodStartDate.month,
      lastPeriodStartDate.day,
    );
    final target = DateTime.utc(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    final daysDifference = target.difference(start).inDays;
    final cycleIndex = (daysDifference % cycleLength + cycleLength) % cycleLength;
    return cycleIndex + 1;
  }

  /// Number of days until the upcoming ovulation
  static int? getDaysUntilOvulation({
    required DateTime targetDate,
    required DateTime? lastPeriodStartDate,
    int cycleLength = 28,
  }) {
    final currentDay = getCurrentCycleDay(
      targetDate: targetDate,
      lastPeriodStartDate: lastPeriodStartDate,
      cycleLength: cycleLength,
    );
    if (currentDay == null) return null;
    final ovulationDay = getOvulationDay(cycleLength);
    if (currentDay <= ovulationDay) {
      return ovulationDay - currentDay;
    } else {
      return (cycleLength - currentDay) + ovulationDay;
    }
  }

  /// Estimated calendar date for the next ovulation
  static DateTime? getNextOvulationDate({
    required DateTime targetDate,
    required DateTime? lastPeriodStartDate,
    int cycleLength = 28,
  }) {
    final daysUntil = getDaysUntilOvulation(
      targetDate: targetDate,
      lastPeriodStartDate: lastPeriodStartDate,
      cycleLength: cycleLength,
    );
    if (daysUntil == null) return null;
    return targetDate.add(Duration(days: daysUntil));
  }

  /// Calculates the upcoming date for "A day before the cycle begins" (1 day before next cycle Day 1).
  static DateTime? getNextDayBeforeCycleStarts({
    required DateTime fromDate,
    required DateTime? lastPeriodStartDate,
    int cycleLength = 28,
    int notificationHour = 10,
    int notificationMinute = 0,
  }) {
    if (lastPeriodStartDate == null) return null;

    final startMidnight = DateTime.utc(
      lastPeriodStartDate.year,
      lastPeriodStartDate.month,
      lastPeriodStartDate.day,
    );
    final currentMidnight = DateTime.utc(
      fromDate.year,
      fromDate.month,
      fromDate.day,
    );
    final daysDiff = currentMidnight.difference(startMidnight).inDays;
    int cycleNumber = daysDiff >= 0
        ? (daysDiff ~/ cycleLength)
        : (-((-daysDiff) ~/ cycleLength) - 1);

    var candidate = startMidnight.add(Duration(days: (cycleNumber + 1) * cycleLength - 1));
    var scheduled = DateTime(
      candidate.year,
      candidate.month,
      candidate.day,
      notificationHour,
      notificationMinute,
    );

    if (scheduled.isBefore(fromDate)) {
      candidate = startMidnight.add(Duration(days: (cycleNumber + 2) * cycleLength - 1));
      scheduled = DateTime(
        candidate.year,
        candidate.month,
        candidate.day,
        notificationHour,
        notificationMinute,
      );
    }
    return scheduled;
  }

  /// Calculates the upcoming date for "A day before the safe window begins".
  /// Post-ovulation caution ends on Day bufferEnd, and Luteal Safe Window
  /// begins on Day (bufferEnd + 1). The day before the safe window is Day bufferEnd.
  static DateTime? getNextDayBeforeSafeWindowStarts({
    required DateTime fromDate,
    required DateTime? lastPeriodStartDate,
    int cycleLength = 28,
    int safetyBufferDays = 2,
    int notificationHour = 10,
    int notificationMinute = 0,
  }) {
    if (lastPeriodStartDate == null) return null;

    final ovulationDay = cycleLength - 14;
    final effectiveBuffer = safetyBufferDays < 2 ? 2 : safetyBufferDays;
    final bufferEnd = (ovulationDay + effectiveBuffer) + 1; // e.g. Day 17 for 28d, buffer 2

    final startMidnight = DateTime.utc(
      lastPeriodStartDate.year,
      lastPeriodStartDate.month,
      lastPeriodStartDate.day,
    );
    final currentMidnight = DateTime.utc(
      fromDate.year,
      fromDate.month,
      fromDate.day,
    );
    final daysDiff = currentMidnight.difference(startMidnight).inDays;
    int cycleNumber = daysDiff >= 0
        ? (daysDiff ~/ cycleLength)
        : (-((-daysDiff) ~/ cycleLength) - 1);

    var cycleStart = startMidnight.add(Duration(days: cycleNumber * cycleLength));
    var candidate = cycleStart.add(Duration(days: bufferEnd - 1));
    var scheduled = DateTime(
      candidate.year,
      candidate.month,
      candidate.day,
      notificationHour,
      notificationMinute,
    );

    if (scheduled.isBefore(fromDate)) {
      cycleStart = startMidnight.add(Duration(days: (cycleNumber + 1) * cycleLength));
      candidate = cycleStart.add(Duration(days: bufferEnd - 1));
      scheduled = DateTime(
        candidate.year,
        candidate.month,
        candidate.day,
        notificationHour,
        notificationMinute,
      );
    }
    return scheduled;
  }
}

