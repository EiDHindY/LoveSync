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

  testWidgets('LoveSyncApp on first launch renders CreateProfileScreen with Google Sign-In', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LoveSyncApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify first launch Google sign-in gate
    expect(find.text('Welcome to LoveSync'), findsOneWidget);
    expect(find.text('WELCOME • SIGN IN TO START'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
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
    expect(find.text('STEP 1 OF 2 • COMPLETE YOUR PROFILE'), findsOneWidget);
    expect(find.text('YOUR NAME OR NICKNAME'), findsOneWidget);
    expect(find.text('I Track My Cycle'), findsOneWidget);
    expect(find.text('I Do Not Track'), findsOneWidget);
  });
}
