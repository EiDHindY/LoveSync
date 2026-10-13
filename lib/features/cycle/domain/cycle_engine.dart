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

    // Viable sperm window: up to 5 days before ovulation
    final coreFertileStart = ovulationDay - 5;
    // Egg viability: up to 1-2 days after ovulation
    final coreFertileEnd = ovulationDay + 1;

    // Safety buffer boundaries
    final bufferStart = coreFertileStart - safetyBufferDays;
    final bufferEnd = coreFertileEnd + 1; // +1 day post-fertile buffer

    // Check Menstruation first
    if (dayOfCycle >= 1 && dayOfCycle <= periodLength) {
      // If cycle is unusually short, period might overlap with fertile buffer
      if (dayOfCycle >= bufferStart) {
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
      return DailyFertilityInfo(
        date: targetDate,
        phase: FertilityPhase.caution,
        dayOfCycle: dayOfCycle,
        cycleLength: cycleLength,
        title: 'Caution / Safety Buffer',
        recommendation:
            'Buffer zone. Protected sex (condom/withdrawal) strongly recommended.',
        rationale:
            'Ovulation can shift by 1–2 days due to stress or hormones. Ejaculation here carries moderate risk.',
      );
    }

    // Safe Window
    final isPostOvulation = dayOfCycle > bufferEnd;
    return DailyFertilityInfo(
      date: targetDate,
      phase: FertilityPhase.safe,
      dayOfCycle: dayOfCycle,
      cycleLength: cycleLength,
      title: isPostOvulation ? 'Safe Window (Post-Ovulation)' : 'Safe Window (Pre-Fertile)',
      recommendation:
          'Lowest probability of pregnancy. Safe for unprotected ejaculation if cycle is regular.',
      rationale: isPostOvulation
          ? 'Egg has dissolved for this cycle; next ovulation cannot occur until the following cycle.'
          : 'Sufficiently far in advance of the estimated ovulation window.',
    );
  }
}
