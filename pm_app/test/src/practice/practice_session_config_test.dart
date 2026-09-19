import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/practice/practice_session_config.dart';

void main() {
  group('PracticeSessionConfig', () {
    test('defines standard launch defaults', () {
      const session = PracticeSessionConfig.standard();

      expect(session.mode, PracticeMode.standard);
      expect(session.initialSection, '1A');
      expect(session.shuffleAnswers, isTrue);
    });

    test('defines review launch defaults', () {
      const session = PracticeSessionConfig.review();

      expect(session.mode, PracticeMode.review);
      expect(session.initialSection, isNull);
      expect(session.shuffleAnswers, isTrue);
    });

    test('defines pending launch data and defaults', () {
      final session = PracticeSessionConfig.pending(
        pendingQuestionCount: 12,
        pendingQuestionCountsBySection: {'1A': 7, '1B': 5},
      );

      expect(session.mode, PracticeMode.pending);
      expect(session.initialSection, isNull);
      expect(session.shuffleAnswers, isTrue);
      expect(session.pendingBatchSize, 10);
      expect(session.pendingLoadThreshold, 5);
      expect(session.pendingQuestionCount, 12);
      expect(session.pendingQuestionCountsBySection, {'1A': 7, '1B': 5});
    });

    test('defensively copies pending counts and supports value equality', () {
      final counts = {'1A': 2};
      final session = PracticeSessionConfig.pending(
        pendingQuestionCount: 2,
        pendingQuestionCountsBySection: counts,
      );
      final equalSession = PracticeSessionConfig.pending(
        pendingQuestionCount: 2,
        pendingQuestionCountsBySection: const {'1A': 2},
      );

      counts['1A'] = 99;

      expect(session.pendingQuestionCountsBySection, {'1A': 2});
      expect(
        () => session.pendingQuestionCountsBySection['1B'] = 1,
        throwsUnsupportedError,
      );
      expect(session, equalSession);
      expect(session.hashCode, equalSession.hashCode);
    });

    test('defines simulacro launch defaults', () {
      const session = PracticeSessionConfig.simulacro();

      expect(session.mode, PracticeMode.simulacro);
      expect(session.initialSection, isNull);
      expect(session.shuffleAnswers, isTrue);
    });

    test('defines single-question launch defaults', () {
      const session = PracticeSessionConfig.singleQuestion();

      expect(session.mode, PracticeMode.singleQuestion);
      expect(session.initialSection, isNull);
      expect(session.shuffleAnswers, isTrue);
    });
  });
}
