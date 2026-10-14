import 'package:flutter_test/flutter_test.dart';
import 'package:love_app/core/services/couple_repository.dart';
import 'package:love_app/features/scheduling/domain/scheduled_intimacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Intimacy Date Night Scheduling', () {
    test('Propose date inserts pending invitation', () async {
      final repo = CoupleRepository();
      final targetDate = DateTime.now().add(const Duration(days: 4));

      await repo.proposeDate(targetDate);

      expect(repo.scheduledDates.length, equals(1));
      final item = repo.scheduledDates.first;
      expect(item.status, equals(IntimacyStatus.pending));
      expect(item.proposedBy, equals(repo.currentUserId));
      expect(item.scheduledAt, equals(targetDate));
    });

    test('Accept date changes status to accepted and creates memory in inbox', () async {
      final repo = CoupleRepository();
      repo.setPartnerForTesting(isPaired: true, partnerName: 'Lola');
      final targetDate = DateTime.now().add(const Duration(days: 2));

      await repo.proposeDate(targetDate);
      final id = repo.scheduledDates.first.id;

      await repo.respondToDate(id, IntimacyStatus.accepted);

      expect(repo.scheduledDates.first.status, equals(IntimacyStatus.accepted));
      expect(repo.memories.length, equals(1));
      expect(repo.memories.first.type, equals('date_night'));
      expect(repo.memories.first.title, equals('Date Night Confirmed! ✨'));
      expect(repo.unreadMemoriesCount, equals(1));
    });

    test('Raincheck converts softly to cuddle/movie with zero guilt', () async {
      final repo = CoupleRepository();
      final targetDate = DateTime.now().add(const Duration(days: 2));

      await repo.proposeDate(targetDate);
      final id = repo.scheduledDates.first.id;

      await repo.respondToDate(id, IntimacyStatus.rainchecked);

      expect(repo.scheduledDates.first.status, equals(IntimacyStatus.rainchecked));
    });

    test('Day-of vibe check responds with confirmed or cuddle', () async {
      final repo = CoupleRepository();
      final targetDate = DateTime.now();

      await repo.proposeDate(targetDate);
      final id = repo.scheduledDates.first.id;
      await repo.respondToDate(id, IntimacyStatus.accepted);

      // Respond to vibe check
      await repo.respondVibeCheck(id, VibeCheckStatus.convertedCuddle);

      expect(
        repo.scheduledDates.first.vibeCheckStatus,
        equals(VibeCheckStatus.convertedCuddle),
      );
    });

    test('Countdown formatting correctly displays days and hours left', () {
      final now = DateTime(2026, 10, 15, 12, 0);

      // 2 days and 5 hours in future
      final futureDate = DateTime(2026, 10, 17, 17, 0);
      expect(
        ScheduledIntimacy.formatDurationUntil(futureDate, from: now),
        equals('2 days, 5 hrs left'),
      );

      // Exactly 1 day in future
      final oneDayDate = DateTime(2026, 10, 16, 12, 0);
      expect(
        ScheduledIntimacy.formatDurationUntil(oneDayDate, from: now),
        equals('1 day left'),
      );

      // 4 hours and 30 minutes in future
      final hoursDate = DateTime(2026, 10, 15, 16, 30);
      expect(
        ScheduledIntimacy.formatDurationUntil(hoursDate, from: now),
        equals('4 hrs, 30 min left'),
      );

      // Past date
      final pastDate = DateTime(2026, 10, 15, 10, 0);
      expect(
        ScheduledIntimacy.formatDurationUntil(pastDate, from: now),
        equals('Passed 2h ago'),
      );
    });
  });
}

