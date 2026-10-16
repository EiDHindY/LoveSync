import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:love_app/features/mood/domain/mood_status.dart';
import 'package:love_app/features/mood/presentation/widgets/spark_button.dart';

void main() {
  testWidgets('SparkButton: when unlit, does NOT show Spark reset timer', (WidgetTester tester) async {
    final unlitStatus = MoodStatus.empty();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SparkButton(
              moodStatus: unlitStatus,
              onToggle: () {},
              partnerName: 'Jane',
              userName: 'John',
            ),
          ),
        ),
      ),
    );

    // Verify "Spark resets at" text is NOT present
    expect(find.textContaining('Spark resets at'), findsNothing);
    expect(find.textContaining('left'), findsNothing);
    expect(find.text('In the mood tonight?'), findsOneWidget);
    expect(find.text("Tap if you're in the mood"), findsOneWidget);
    expect(find.text('Tap to be in the mood'), findsNothing);
  });

  testWidgets('SparkButton: when lit, shows Spark active timer', (WidgetTester tester) async {
    final litStatus = MoodStatus(
      userInTheMood: true,
      isMatch: false,
      signalDate: DateTime.now(),
      hasCouple: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SparkButton(
              moodStatus: litStatus,
              onToggle: () {},
              partnerName: 'Jane',
              userName: 'John',
            ),
          ),
        ),
      ),
    );

    // Verify "Spark active until" is shown, but NOT "Spark resets at"
    expect(find.textContaining('Spark active until'), findsOneWidget);
    expect(find.textContaining('Spark resets at'), findsNothing);
  });
}
