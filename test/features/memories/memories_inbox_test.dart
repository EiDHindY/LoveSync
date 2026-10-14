import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/memories/domain/couple_memory.dart';
import 'package:love_app/features/memories/presentation/memories_inbox_modal.dart';

void main() {
  testWidgets('MemoriesInboxModal renders empty state when no memories', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: MemoriesInboxModal(memories: []),
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
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: MemoriesInboxModal(memories: memories),
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
}
