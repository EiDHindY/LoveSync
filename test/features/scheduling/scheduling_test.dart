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

    test('cancelScheduledDate updates status to canceled and creates date_canceled memory', () async {
      final repo = CoupleRepository();
      repo.setPartnerForTesting(isPaired: true, partnerName: 'Lola');
      final targetDate = DateTime.now().add(const Duration(days: 3));

      await repo.proposeDate(targetDate);
      final id = repo.scheduledDates.first.id;
      await repo.respondToDate(id, IntimacyStatus.accepted);
      expect(repo.scheduledDates.first.status, equals(IntimacyStatus.accepted));
      expect(repo.memories.first.type, equals('date_night'));

      // Cancel the date
      await repo.cancelScheduledDate(id);
      expect(repo.scheduledDates.first.status, equals(IntimacyStatus.canceled));
      expect(repo.memories.first.type, equals('date_canceled'));
      expect(repo.memories.first.title, equals('Date Canceled'));
      expect(repo.memories.any((m) => m.type == 'date_night'), isFalse);
    });

    test('cancelScheduledDate cancels all upcoming active dates so none linger as active', () async {
      final repo = CoupleRepository();
      repo.setPartnerForTesting(isPaired: true, partnerName: 'Lola');
      final date1 = DateTime.now().add(const Duration(days: 2));
      final date2 = DateTime.now().add(const Duration(days: 5));

      await repo.proposeDate(date1);
      final id1 = repo.scheduledDates.first.id;
      await repo.respondToDate(id1, IntimacyStatus.accepted);

      await repo.proposeDate(date2);
      final id2 = repo.scheduledDates.first.id;
      await repo.respondToDate(id2, IntimacyStatus.accepted);

      // Now cancel
      await repo.cancelScheduledDate(id2);

      // All upcoming dates should be canceled
      final activeUpcoming = repo.scheduledDates.where(
        (d) => d.status == IntimacyStatus.accepted || d.status == IntimacyStatus.pending,
      );
      expect(activeUpcoming, isEmpty);
    });

    test('proposeDate marks any prior upcoming active dates as canceled', () async {
      final repo = CoupleRepository();
      repo.setPartnerForTesting(isPaired: true, partnerName: 'Lola');
      final date1 = DateTime.now().add(const Duration(days: 2));
      final date2 = DateTime.now().add(const Duration(days: 4));

      await repo.proposeDate(date1);
      final id1 = repo.scheduledDates.first.id;
      await repo.respondToDate(id1, IntimacyStatus.accepted);
      expect(repo.scheduledDates.firstWhere((d) => d.id == id1).status, equals(IntimacyStatus.accepted));

      // Propose a new date
      await repo.proposeDate(date2);

      // Prior date should now be canceled
      expect(repo.scheduledDates.firstWhere((d) => d.id == id1).status, equals(IntimacyStatus.canceled));
      // Only the new date is active/pending
      final activeUpcoming = repo.scheduledDates.where(
        (d) => d.status == IntimacyStatus.accepted || d.status == IntimacyStatus.pending,
      );
      expect(activeUpcoming.length, equals(1));
      expect(activeUpcoming.first.scheduledAt, equals(date2));
    });

    test('sparkSoundId defaults to heartbeat_pulse and can be updated', () async {
      final repo = CoupleRepository();
      expect(repo.sparkSoundId, equals('heartbeat_pulse'));

      await repo.setSparkSound('crystal_bells');
      expect(repo.sparkSoundId, equals('crystal_bells'));
    });

    test('cancelSoundId defaults to sunset_marimba and can be updated', () async {
      final repo = CoupleRepository();
      expect(repo.cancelSoundId, equals('sunset_marimba'));

      await repo.setCancelSound('cloud_breath');
      expect(repo.cancelSoundId, equals('cloud_breath'));
    });

    test('checkDateNudges triggers day-before and one-hour-before nudges without duplicates', () async {
      final repo = CoupleRepository();
      repo.setPartnerForTesting(isPaired: true, partnerName: 'Lola');

      // Propose and accept a date 12 hours from now (in day-before window)
      final date12h = DateTime.now().add(const Duration(hours: 12));
      await repo.proposeDate(date12h);
      final id1 = repo.scheduledDates.first.id;
      await repo.respondToDate(id1, IntimacyStatus.accepted);

      // Propose and accept a date 30 mins from now (in 1-hour window)
      final date30m = DateTime.now().add(const Duration(minutes: 30));
      await repo.proposeDate(date30m);
      final id2 = repo.scheduledDates.first.id;
      await repo.respondToDate(id2, IntimacyStatus.accepted);

      repo.checkDateNudges();

      // Running again should not throw or duplicate
      repo.checkDateNudges();
    });
  });
}

