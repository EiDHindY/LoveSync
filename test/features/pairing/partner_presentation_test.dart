import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:love_app/core/providers/app_providers.dart';
import 'package:love_app/core/services/couple_repository.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:love_app/features/pairing/presentation/partner_info_modal.dart';
import 'package:love_app/features/pairing/presentation/pairing_modal.dart';
import 'package:love_app/features/scheduling/presentation/widgets/scheduled_date_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestDashboard({
    required bool isPaired,
    String partnerName = '',
    String partnerRole = 'Partner',
    bool partnerTracksCycle = true,
    String inviteCode = 'LOVE-5839',
  }) {
    final repo = CoupleRepository();

    repo.setPartnerForTesting(
      isPaired: isPaired,
      partnerName: partnerName,
      partnerRole: partnerRole,
      partnerTracksCycle: partnerTracksCycle,
      inviteCode: inviteCode,
    );

    return ProviderScope(
      overrides: [
        coupleRepositoryProvider.overrideWith((ref) => repo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const DashboardScreen(),
      ),
    );
  }

  testWidgets('When paired: displays My Partner, avatar, name, and opens PartnerInfoModal with Remove option', (tester) async {
    await tester.pumpWidget(
      buildTestDashboard(
        isPaired: true,
        partnerName: 'Lola',
        partnerRole: 'Wife',
        partnerTracksCycle: true,
        inviteCode: 'LOVE-5839',
      ),
    );
    await tester.pumpAndSettle();

    // Verify AppBar displays "My Partner" and "Lola" in top-right partner chip
    expect(find.text('My Partner'), findsOneWidget);
    expect(find.text('Lola'), findsOneWidget);
    expect(find.text('L'), findsOneWidget); // Avatar initial in AppBar
    // Redundant horizontal card is removed when paired
    expect(find.text('My Partner • Lola'), findsNothing);
    expect(find.text('Synced'), findsNothing);

    // Tap on the Partner chip in AppBar to open PartnerInfoModal
    await tester.tap(find.text('Lola'));
    await tester.pumpAndSettle();

    // Verify PartnerInfoModal is shown with info
    expect(find.byType(PartnerInfoModal), findsOneWidget);
    expect(find.text('My Partner • Synced in Real Time'), findsOneWidget);
    expect(find.text('Tracks Menstrual Cycle'), findsOneWidget);
    expect(find.text('LOVE-5839'), findsOneWidget);
    expect(find.text('Remove as Partner'), findsOneWidget);

    // Tap Remove as Partner
    await tester.tap(find.text('Remove as Partner'));
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('Remove Partner?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('When unpaired: displays Add Partner and opens PairingModal', (tester) async {
    await tester.pumpWidget(
      buildTestDashboard(
        isPaired: false,
        inviteCode: 'LOVE-1234',
      ),
    );
    await tester.pumpAndSettle();

    // Verify "Add Partner" button is present and "My Partner" is not
    expect(find.text('Add Partner'), findsWidgets);
    expect(find.text('Connect Your Partner'), findsOneWidget);
    expect(find.text('My Partner'), findsNothing);

    // Tap on Add Partner in AppBar
    await tester.tap(find.text('Add Partner').first);
    await tester.pumpAndSettle();

    // Verify PairingModal is opened
    expect(find.byType(PairingModal), findsOneWidget);
    expect(find.text('Couple Pairing & Sync'), findsOneWidget);
  });

  testWidgets('Two tabs: switches between Sex & Intimacy and Cycle & Period tabs', (tester) async {
    await tester.pumpWidget(
      buildTestDashboard(
        isPaired: true,
        partnerName: 'Lola',
        partnerRole: 'Wife',
        partnerTracksCycle: true,
        inviteCode: 'LOVE-5839',
      ),
    );
    await tester.pumpAndSettle();

    // Verify Tab 1 (Sex & Intimacy) is visible initially
    expect(find.text('Sex & Intimacy'), findsOneWidget);
    expect(find.text('Cycle & Period'), findsOneWidget);
    expect(find.textContaining('In the mood'), findsOneWidget);
    expect(find.textContaining('Light My Spark'), findsOneWidget);

    // Tap on Cycle & Period tab
    await tester.tap(find.text('Cycle & Period'));
    await tester.pumpAndSettle();

    // Verify Tab 2 (Cycle & Period) content is visible
    expect(find.text('NATURAL RHYTHM'), findsOneWidget);
    expect(find.text('Log Period / Adjust Parameters'), findsOneWidget);
  });

  testWidgets('Tonight Alignment is removed and user Google avatar is displayed next to My Partner', (tester) async {
    final repo = CoupleRepository();
    repo.setUserEmailForTesting('alex@gmail.com');
    repo.setPartnerForTesting(
      isPaired: true,
      partnerName: 'Lola',
      partnerRole: 'Wife',
      partnerTracksCycle: true,
      inviteCode: 'LOVE-5839',
      partnerAvatarUrl: 'https://example.com/lola.jpg',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coupleRepositoryProvider.overrideWith((ref) => repo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Tonight's Alignment text is absent
    expect(find.text("TONIGHT'S ALIGNMENT"), findsNothing);

    // Verify My Partner pill is shown
    expect(find.text('My Partner'), findsOneWidget);

    // Verify User Account avatar initial is present next to My Partner
    expect(find.text('U'), findsOneWidget);

    // Tap on the user avatar to open user profile modal
    await tester.tap(find.text('U'));
    await tester.pumpAndSettle();

    // Verify user profile modal opens with email and status
    expect(find.text('alex@gmail.com'), findsOneWidget);
    expect(find.text('Your Role'), findsOneWidget);
    expect(find.text('Connection Status'), findsOneWidget);
  });

  testWidgets('When unpaired: shows default schedule date section even if dates exist and prompts to pair', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repo = CoupleRepository();
    repo.setPartnerForTesting(
      isPaired: false,
    );
    // Add a date that would otherwise show if paired
    await repo.proposeDate(DateTime.now().add(const Duration(days: 3)));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coupleRepositoryProvider.overrideWith((ref) => repo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify default schedule date section is displayed, not an active date card
    expect(find.text('No upcoming date scheduled'), findsOneWidget);
    expect(find.text('Schedule a Date'), findsOneWidget);

    final dateCard = tester.widget<ScheduledDateCard>(find.byType(ScheduledDateCard));
    expect(dateCard.dateItem, isNull);

    // Call onOpenScheduleModal directly
    dateCard.onOpenScheduleModal();
    await tester.pumpAndSettle();

    // Verify prompt to pair and PairingModal opens
    expect(find.text('Pair with your partner first to schedule a date night together!'), findsOneWidget);
    expect(find.byType(PairingModal), findsOneWidget);
  });
}
