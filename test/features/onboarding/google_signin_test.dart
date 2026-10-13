import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:love_app/core/providers/app_providers.dart';
import 'package:love_app/core/services/couple_repository.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/onboarding/presentation/create_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget({String userEmail = ''}) {
    final repo = CoupleRepository();
    if (userEmail.isNotEmpty) {
      repo.setUserEmailForTesting(userEmail);
    }

    return ProviderScope(
      overrides: [
        coupleRepositoryProvider.overrideWith((ref) => repo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const CreateProfileScreen(),
      ),
    );
  }

  testWidgets('CreateProfileScreen requires Google Sign-In and removes manual setup', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('WELCOME • SIGN IN TO START'), findsOneWidget);
    expect(find.text('OR SET UP MANUALLY'), findsNothing);
    expect(find.text('Privacy PIN & Backup (Optional)'), findsNothing);
    expect(
      find.text('Sign in required to restore & sync your couple space on any device.'),
      findsOneWidget,
    );
  });

  testWidgets('CreateProfileScreen shows profile fields only after Google Sign-In', (tester) async {
    await tester.pumpWidget(buildTestWidget(userEmail: 'user@example.com'));
    await tester.pumpAndSettle();

    expect(find.text('Signed in with Google'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('YOUR NAME OR NICKNAME'), findsOneWidget);
    expect(find.text('Continue to Step 2 • Connect Partner'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
    expect(find.text('Privacy PIN & Backup (Optional)'), findsNothing);
  });
}
