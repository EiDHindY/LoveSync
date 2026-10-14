import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:love_app/core/providers/app_providers.dart';
import 'package:love_app/core/services/couple_repository.dart';
import 'package:love_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LoveSyncApp on first launch renders WelcomeScreen with Get Started and Log In', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LoveSyncApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify first launch WelcomeScreen gate
    expect(find.text('LoveSync'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.textContaining('Log In'), findsOneWidget);
  });

  testWidgets('LoveSyncApp shows profile completion once authenticated', (WidgetTester tester) async {
    final repo = CoupleRepository();
    repo.setUserEmailForTesting('testuser@gmail.com');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coupleRepositoryProvider.overrideWith((ref) => repo),
        ],
        child: const LoveSyncApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Step 1: Complete profile once signed in
    expect(find.text('Complete Your Profile'), findsOneWidget);
    expect(find.text('COMPLETE YOUR PROFILE'), findsOneWidget);
    expect(find.text('YOUR NAME OR NICKNAME'), findsOneWidget);
    expect(find.text('I Track My Cycle'), findsOneWidget);
    expect(find.text('I Do Not Track'), findsOneWidget);
  });
}
