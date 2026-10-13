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
  });
}
