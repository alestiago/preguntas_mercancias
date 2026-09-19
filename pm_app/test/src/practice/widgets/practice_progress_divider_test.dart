import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/app/theme/app_theme.dart';
import 'package:pm_app/src/practice/practice_question_policy.dart';
import 'package:pm_app/src/practice/widgets/practice_progress_divider.dart';

void main() {
  testWidgets('renders visible progress segments', (tester) async {
    await tester.pumpWidget(
      _buildDivider(
        currentIndex: 0,
        segments: const [
          SessionQuestionStatus.unanswered,
          SessionQuestionStatus.correct,
          SessionQuestionStatus.incorrect,
        ],
      ),
    );

    final stripSegmentBoxes = find.descendant(
      of: find.byType(PracticeProgressDivider),
      matching: find.byType(ColoredBox),
    );
    final currentSegment = find.descendant(
      of: find.byType(PracticeProgressDivider),
      matching: find.byType(Container),
    );

    expect(stripSegmentBoxes, findsNWidgets(2));
    expect(currentSegment, findsOneWidget);
    for (final element in stripSegmentBoxes.evaluate()) {
      final renderBox = element.renderObject! as RenderBox;
      expect(renderBox.size.height, 3);
      expect(renderBox.size.width, greaterThan(0));
    }

    final currentRenderBox =
        currentSegment.evaluate().single.renderObject! as RenderBox;
    expect(currentRenderBox.size.height, 7);
    expect(currentRenderBox.size.width, greaterThan(0));
  });

  testWidgets('colors the current segment with the primary color', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildDivider(
        currentIndex: 1,
        segments: const [
          SessionQuestionStatus.unanswered,
          SessionQuestionStatus.unanswered,
          SessionQuestionStatus.correct,
        ],
      ),
    );

    final stripSegmentBoxes = tester.widgetList<ColoredBox>(
      find.descendant(
        of: find.byType(PracticeProgressDivider),
        matching: find.byType(ColoredBox),
      ),
    );
    final currentSegment = tester.widget<Container>(
      find.descendant(
        of: find.byType(PracticeProgressDivider),
        matching: find.byType(Container),
      ),
    );
    final decoration = currentSegment.decoration! as BoxDecoration;
    final theme = AppTheme.light;
    final resultColors = theme.extension<AppResultColors>()!;

    expect(stripSegmentBoxes.map((segment) => segment.color), [
      theme.colorScheme.outline,
      resultColors.correct,
    ]);
    expect(decoration.color, theme.colorScheme.primary);
    expect(decoration.border, Border.all(color: theme.colorScheme.surface));
    expect(
      decoration.borderRadius,
      BorderRadius.circular(AppLayout.pillRadius),
    );
  });

  testWidgets('keeps correct and incorrect completed segments green', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildDivider(
        currentIndex: 2,
        segments: const [
          SessionQuestionStatus.unanswered,
          SessionQuestionStatus.correct,
          SessionQuestionStatus.incorrect,
        ],
      ),
    );

    final stripSegmentBoxes = tester.widgetList<ColoredBox>(
      find.descendant(
        of: find.byType(PracticeProgressDivider),
        matching: find.byType(ColoredBox),
      ),
    );
    final currentSegment = tester.widget<Container>(
      find.descendant(
        of: find.byType(PracticeProgressDivider),
        matching: find.byType(Container),
      ),
    );
    final decoration = currentSegment.decoration! as BoxDecoration;
    final theme = AppTheme.light;
    final resultColors = theme.extension<AppResultColors>()!;

    expect(stripSegmentBoxes.map((segment) => segment.color), [
      theme.colorScheme.outline,
      resultColors.correct,
    ]);
    expect(decoration.color, theme.colorScheme.primary);
  });
}

Widget _buildDivider({
  required int currentIndex,
  required List<SessionQuestionStatus> segments,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Center(
      child: SizedBox(
        width: 300,
        child: PracticeProgressDivider(
          currentIndex: currentIndex,
          segments: segments,
        ),
      ),
    ),
  );
}
