import 'package:flutter_test/flutter_test.dart';

import '../src/support/fixture_factory.dart';

void main() {
  test('builds home progress through the real HomeLoaded policy', () {
    final state = WidgetbookFixtures.homeProgress(
      correctCount: 4,
      incorrectCount: 3,
      unansweredCount: 2,
    );

    expect(state.correctQuestionCount, 4);
    expect(state.incorrectQuestionCount, 3);
    expect(state.unansweredQuestionCount, 2);
    expect(state.totalQuestionCount, 9);
  });

  test('supports the all-zero progress boundary', () {
    final state = WidgetbookFixtures.homeProgress(
      correctCount: 0,
      incorrectCount: 0,
      unansweredCount: 0,
    );

    expect(state.totalQuestionCount, 0);
  });

  test('can include a history record whose question is unavailable', () {
    final section = WidgetbookFixtures.historySection(
      date: DateTime(2026, 9, 20),
      entryCount: 2,
      includeMissingQuestion: true,
    );

    expect(section.entries, hasLength(2));
    expect(section.entries.last.question, isNull);
  });
}
