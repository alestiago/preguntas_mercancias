import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/practice/widgets/practice_progress_divider.dart';

void main() {
  testWidgets('renders visible progress segments', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 300,
            child: PracticeProgressDivider(
              currentIndex: 0,
              segments: [
                PracticeProgressSegmentStatus.pending,
                PracticeProgressSegmentStatus.correct,
                PracticeProgressSegmentStatus.incorrect,
              ],
            ),
          ),
        ),
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

  testWidgets('colors the current segment as a blue pill', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 300,
            child: PracticeProgressDivider(
              currentIndex: 1,
              segments: [
                PracticeProgressSegmentStatus.pending,
                PracticeProgressSegmentStatus.pending,
                PracticeProgressSegmentStatus.correct,
              ],
            ),
          ),
        ),
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

    expect(stripSegmentBoxes.map((segment) => segment.color), [
      Colors.grey,
      const Color(0xFF2E7D32),
    ]);
    expect(decoration.color, const Color(0xFF1976D2));
    expect(decoration.border, Border.all(color: Colors.white));
    expect(decoration.borderRadius, BorderRadius.circular(999));
  });

  testWidgets('colors the current answered segment blue', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 300,
            child: PracticeProgressDivider(
              currentIndex: 2,
              segments: [
                PracticeProgressSegmentStatus.pending,
                PracticeProgressSegmentStatus.correct,
                PracticeProgressSegmentStatus.incorrect,
              ],
            ),
          ),
        ),
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

    expect(stripSegmentBoxes.map((segment) => segment.color), [
      Colors.grey,
      const Color(0xFF2E7D32),
    ]);
    expect(decoration.color, const Color(0xFF1976D2));
  });
}
