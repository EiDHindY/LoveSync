import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/memories/domain/couple_memory.dart';
import 'package:love_app/features/memories/presentation/memories_inbox_modal.dart';

void main() {
  testWidgets('MemoriesInboxModal renders empty state when no memories', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: MemoriesInboxModal(memories: []),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Memories & Spark Inbox'), findsOneWidget);
    expect(find.text('No Memories Yet'), findsOneWidget);
    expect(find.text('Your shared intimacy timeline'), findsOneWidget);
  });

  testWidgets('MemoriesInboxModal renders documented spark events', (tester) async {
    final memories = [
      CoupleMemory(
        id: '1',
        coupleId: 'couple-1',
        type: 'spark_celebrated',
        title: 'Spark Celebrated! 🎉',
        description: 'You and Lola celebrated this spark!',
        windowKey: '2026-10-14-DAY',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      CoupleMemory(
        id: '2',
        coupleId: 'couple-1',
        type: 'spark_match',
        title: 'Spark Ignited! 🔥',
        description: 'Mutual match! Both of you lit your sparks.',
        windowKey: '2026-10-14-DAY',
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MemoriesInboxModal(memories: memories),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Memories & Spark Inbox'), findsOneWidget);
    expect(find.text('2 documented moments'), findsOneWidget);
    expect(find.text('Spark Celebrated! 🎉'), findsOneWidget);
    expect(find.text('Spark Ignited! 🔥'), findsOneWidget);
    expect(find.text('2026-10-14-DAY'), findsNWidgets(2));
  });

  testWidgets('MemoriesInboxModal renders two sections for Mutual Sparks and Scheduled Dates', (tester) async {
    final memories = [
      CoupleMemory(
        id: '1',
        coupleId: 'couple-1',
        type: 'spark_match',
        title: 'Spark Ignited! 🔥',
        description: 'Mutual match! Both of you lit your sparks.',
        windowKey: '2026-10-15-NIGHT',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      CoupleMemory(
        id: '2',
        coupleId: 'couple-1',
        type: 'date_night',
        title: 'Date Night Confirmed! ✨',
        description: 'Date scheduled with Lola for Friday.',
        windowKey: 'Fri, Oct 16',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MemoriesInboxModal(memories: memories),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify both section headers exist
    expect(find.text('MUTUAL SPARKS'), findsOneWidget);
    expect(find.text('SCHEDULED DATES'), findsOneWidget);

    // Verify items in each section
    expect(find.text('Spark Ignited! 🔥'), findsOneWidget);
    expect(find.text('Date Night Confirmed! ✨'), findsOneWidget);

    // Verify filter pills
    expect(find.text('All (2)'), findsOneWidget);
    expect(find.text('Mutual Sparks (1)'), findsOneWidget);
    expect(find.text('Scheduled Dates (1)'), findsOneWidget);
    expect(find.text('Direct Chat'), findsOneWidget);

    // Tap on Scheduled Dates filter pill
    await tester.tap(find.text('Scheduled Dates (1)'));
    await tester.pumpAndSettle();

    // Only Scheduled Dates section is visible
    expect(find.text('SCHEDULED DATES'), findsOneWidget);
    expect(find.text('MUTUAL SPARKS'), findsNothing);
  });

  testWidgets('MemoriesInboxModal switches to Direct Chat tab', (tester) async {
    bool pairingOpened = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MemoriesInboxModal(
              memories: const [],
              onOpenPairing: () {
                pairingOpened = true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Direct Chat'), findsOneWidget);
    await tester.ensureVisible(find.text('Direct Chat'));
    await tester.tap(find.text('Direct Chat'));
    await tester.pumpAndSettle();

    // Since repository is not paired in default test state, it should show unpaired prompt
    expect(find.text('Pair to Start Chatting'), findsOneWidget);
    expect(find.text('Add Partner'), findsOneWidget);

    await tester.tap(find.text('Add Partner'));
    await tester.pumpAndSettle();

    expect(pairingOpened, isTrue);
  });
}
