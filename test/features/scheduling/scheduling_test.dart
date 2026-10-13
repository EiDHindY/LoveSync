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

    test('Accept date changes status to accepted', () async {
      final repo = CoupleRepository();
      final targetDate = DateTime.now().add(const Duration(days: 2));

      await repo.proposeDate(targetDate);
      final id = repo.scheduledDates.first.id;

      await repo.respondToDate(id, IntimacyStatus.accepted);

      expect(repo.scheduledDates.first.status, equals(IntimacyStatus.accepted));
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
  });
}
