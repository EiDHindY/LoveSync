import 'package:flutter_test/flutter_test.dart';
import 'package:love_app/core/services/couple_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Zero-Pressure Double-Blind Mood Matching', () {
    test('Neither partner signaled: no match and no mood', () async {
      final repo = CoupleRepository();
      await repo.setupNewUser(displayName: 'Husband', role: 'husband');
      await repo.pairWithCode('LOVE-1234');

      final status = repo.getDailyMoodStatus();
      expect(status.userInTheMood, isFalse);
      expect(status.isMatch, isFalse);
    });

    test('Partner A signals: Partner B cannot detect any information', () async {
      final repo = CoupleRepository();
      await repo.setupNewUser(displayName: 'Husband', role: 'husband');
      await repo.pairWithCode('LOVE-1234');

      // Partner A (Husband) toggles mood
      await repo.toggleMoodSignal();

      final partnerAStatus = repo.getDailyMoodStatus();
      expect(partnerAStatus.userInTheMood, isTrue);
      expect(partnerAStatus.isMatch, isFalse); // No match yet because B has not signaled

      // Switch to Partner B perspective
      repo.switchPartnerView();

      final partnerBStatus = repo.getDailyMoodStatus();
      // CRITICAL ZERO-KNOWLEDGE CHECK:
      // Partner B must see userInTheMood == false and isMatch == false.
      // Partner B receives ZERO hint that Partner A is in the mood!
      expect(partnerBStatus.userInTheMood, isFalse);
      expect(partnerBStatus.isMatch, isFalse);
    });

    test('Both partners signal: Instant match celebration triggered', () async {
      final repo = CoupleRepository();
      await repo.setupNewUser(displayName: 'Husband', role: 'husband');
      await repo.pairWithCode('LOVE-1234');

      // Partner A lights spark
      await repo.toggleMoodSignal();
      expect(repo.getDailyMoodStatus().isMatch, isFalse);

      // Partner B lights spark
      repo.switchPartnerView();
      await repo.toggleMoodSignal();

      // Now both have signaled -> isMatch MUST be true!
      final partnerBStatus = repo.getDailyMoodStatus();
      expect(partnerBStatus.userInTheMood, isTrue);
      expect(partnerBStatus.isMatch, isTrue);

      // Partner A also sees match
      repo.switchPartnerView();
      final partnerAStatus = repo.getDailyMoodStatus();
      expect(partnerAStatus.userInTheMood, isTrue);
      expect(partnerAStatus.isMatch, isTrue);
    });

    test('Toggling off clears the match', () async {
      final repo = CoupleRepository();
      await repo.setupNewUser(displayName: 'Husband', role: 'husband');
      await repo.pairWithCode('LOVE-1234');

      // Both light spark
      await repo.toggleMoodSignal();
      repo.switchPartnerView();
      await repo.toggleMoodSignal();
      expect(repo.getDailyMoodStatus().isMatch, isTrue);

      // Partner B turns off spark
      await repo.toggleMoodSignal();
      expect(repo.getDailyMoodStatus().isMatch, isFalse);
      expect(repo.getDailyMoodStatus().userInTheMood, isFalse);

      // Partner A also has match cleared
      repo.switchPartnerView();
      expect(repo.getDailyMoodStatus().isMatch, isFalse);
      expect(repo.getDailyMoodStatus().userInTheMood, isTrue);
    });

    test('Mutual match logs spark_match memory, and turnOffSparkMatch turns off both and logs spark_celebrated', () async {
      final repo = CoupleRepository();
      await repo.setupNewUser(displayName: 'Husband', role: 'husband');
      await repo.pairWithCode('LOVE-1234');

      // Partner A lights spark
      await repo.toggleMoodSignal();
      expect(repo.memories, isEmpty);

      // Partner B lights spark -> triggers mutual match
      repo.switchPartnerView();
      await repo.toggleMoodSignal();
      expect(repo.getDailyMoodStatus().isMatch, isTrue);

      // Verify spark_match memory is logged in inbox
      expect(repo.memories.length, 1);
      expect(repo.memories.first.type, 'spark_match');
      expect(repo.memories.first.title, contains('Spark Ignited'));

      // Partner B cancels spark match for both
      await repo.turnOffSparkMatch();

      // Verify spark is turned off on Partner B's device
      expect(repo.getDailyMoodStatus().isMatch, isFalse);
      expect(repo.getDailyMoodStatus().userInTheMood, isFalse);

      // Verify spark is turned off on Partner A's device as well
      repo.switchPartnerView();
      expect(repo.getDailyMoodStatus().isMatch, isFalse);
      expect(repo.getDailyMoodStatus().userInTheMood, isFalse);

      // Verify spark_canceled memory is logged in inbox
      expect(repo.memories.length, 2);
      expect(repo.memories.first.type, 'spark_canceled');
      expect(repo.memories.first.title, contains('Spark Canceled'));
    });
  });
}
