import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:love_app/core/services/couple_repository.dart';
import 'package:love_app/features/cycle/domain/cycle_engine.dart';
import 'package:love_app/features/cycle/domain/fertility_status.dart';
import 'package:love_app/features/mood/domain/mood_status.dart';
import 'package:love_app/features/scheduling/domain/scheduled_intimacy.dart';

final coupleRepositoryProvider = ChangeNotifierProvider<CoupleRepository>((ref) {
  return CoupleRepository();
});

final todayFertilityProvider = Provider<DailyFertilityInfo>((ref) {
  final repo = ref.watch(coupleRepositoryProvider);
  return CycleEngine.calculateFertility(
    targetDate: DateTime.now(),
    lastPeriodStartDate: repo.lastPeriodStartDate,
    cycleLength: repo.cycleLength,
    periodLength: repo.periodLength,
    safetyBufferDays: repo.safetyBufferDays,
  );
});

final todayMoodStatusProvider = Provider<MoodStatus>((ref) {
  final repo = ref.watch(coupleRepositoryProvider);
  return repo.getDailyMoodStatus();
});

final scheduledDatesProvider = Provider<List<ScheduledIntimacy>>((ref) {
  final repo = ref.watch(coupleRepositoryProvider);
  return repo.scheduledDates;
});
