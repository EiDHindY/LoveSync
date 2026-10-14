import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:love_app/core/services/couple_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('CoupleRepository unread memories count tracks read state and marks read', () async {
    final repo = CoupleRepository();
    // Simulate being paired
    repo.setPartnerForTesting(isPaired: true, partnerName: 'Lola');

    expect(repo.unreadMemoriesCount, equals(0));

    // Simulate celebrating a spark which generates a memory
    await repo.turnOffSparkMatch();

    expect(repo.memories.length, equals(1));
    expect(repo.unreadMemoriesCount, equals(1));
    expect(repo.isMemoryRead(repo.memories.first.id), isFalse);

    // Now mark memories as read (e.g. user opens inbox)
    await repo.markMemoriesAsRead();

    expect(repo.unreadMemoriesCount, equals(0));
    expect(repo.isMemoryRead(repo.memories.first.id), isTrue);

    // Another spark memory generated in next cycle window
    await repo.turnOffSparkMatch(DateTime.now().add(const Duration(hours: 13)));
    expect(repo.memories.length, equals(2));
    expect(repo.unreadMemoriesCount, equals(1));

    // Marking read again clears unread count
    await repo.markMemoriesAsRead();
    expect(repo.unreadMemoriesCount, equals(0));
  });

  test('CoupleRepository resetToOnboarding clears read memories state', () async {
    final repo = CoupleRepository();
    repo.setPartnerForTesting(isPaired: true, partnerName: 'Lola');
    await repo.turnOffSparkMatch();
    await repo.markMemoriesAsRead();
    expect(repo.unreadMemoriesCount, equals(0));

    await repo.resetToOnboarding();
    expect(repo.memories.isEmpty, isTrue);
    expect(repo.unreadMemoriesCount, equals(0));
  });
}
