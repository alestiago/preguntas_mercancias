import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/practice/practice_session_config.dart';

void main() {
  group('PracticeSessionConfig', () {
    test('defines capabilities for all five modes', () {
      final cases = [
        (
          config: const PracticeSessionConfig.standard(),
          mode: PracticeMode.standard,
          allowsSections: true,
          allowsNavigation: false,
          showsElapsedTime: false,
          showsExitAction: false,
          confirmsExit: false,
          usesFilteredEligibility: false,
          completionPolicy: PracticeCompletionPolicy.restartAtTerminalQuestion,
          destination: null,
        ),
        (
          config: const PracticeSessionConfig.review(),
          mode: PracticeMode.review,
          allowsSections: true,
          allowsNavigation: false,
          showsElapsedTime: false,
          showsExitAction: false,
          confirmsExit: false,
          usesFilteredEligibility: true,
          completionPolicy:
              PracticeCompletionPolicy.finishWhenEligibleQuestionsExhausted,
          destination: PracticeCompletionDestination.previousRoute,
        ),
        (
          config: PracticeSessionConfig.pending(),
          mode: PracticeMode.pending,
          allowsSections: true,
          allowsNavigation: false,
          showsElapsedTime: false,
          showsExitAction: false,
          confirmsExit: false,
          usesFilteredEligibility: true,
          completionPolicy:
              PracticeCompletionPolicy.finishWhenEligibleQuestionsExhausted,
          destination: PracticeCompletionDestination.previousRoute,
        ),
        (
          config: const PracticeSessionConfig.simulacro(),
          mode: PracticeMode.simulacro,
          allowsSections: false,
          allowsNavigation: true,
          showsElapsedTime: true,
          showsExitAction: true,
          confirmsExit: true,
          usesFilteredEligibility: false,
          completionPolicy:
              PracticeCompletionPolicy.finishAtTerminalQuestionAllowingSkipped,
          destination: PracticeCompletionDestination.summary,
        ),
        (
          config: const PracticeSessionConfig.singleQuestion(),
          mode: PracticeMode.singleQuestion,
          allowsSections: false,
          allowsNavigation: false,
          showsElapsedTime: false,
          showsExitAction: false,
          confirmsExit: false,
          usesFilteredEligibility: false,
          completionPolicy:
              PracticeCompletionPolicy.finishAtTerminalQuestionAllowingSkipped,
          destination: PracticeCompletionDestination.previousRoute,
        ),
      ];

      for (final testCase in cases) {
        final config = testCase.config;
        expect(config.mode, testCase.mode);
        expect(config.allowsSectionSelection, testCase.allowsSections);
        expect(config.allowsQuestionNavigation, testCase.allowsNavigation);
        expect(config.showsElapsedTime, testCase.showsElapsedTime);
        expect(config.showsExitAction, testCase.showsExitAction);
        expect(config.confirmsExitAfterAnswer, testCase.confirmsExit);
        expect(
          config.usesFilteredQuestionEligibility,
          testCase.usesFilteredEligibility,
        );
        expect(config.completionPolicy, testCase.completionPolicy);
        expect(config.completionDestination, testCase.destination);
        expect(
          config.pendingOptions == null,
          testCase.mode != PracticeMode.pending,
        );
      }
    });

    test('defines launch defaults', () {
      const standard = PracticeSessionConfig.standard();
      const review = PracticeSessionConfig.review();
      final pending = PracticeSessionConfig.pending();
      const simulacro = PracticeSessionConfig.simulacro();
      const singleQuestion = PracticeSessionConfig.singleQuestion();

      expect(standard.initialSection, '1A');
      expect(review.initialSection, isNull);
      expect(pending.initialSection, isNull);
      expect(simulacro.initialSection, isNull);
      expect(singleQuestion.initialSection, isNull);
      expect(
        [
          standard,
          review,
          pending,
          simulacro,
          singleQuestion,
        ].map((config) => config.shuffleAnswers),
        everyElement(isTrue),
      );
    });
  });

  group('PendingPracticeOptions', () {
    test('contains pending-only batching and launch metadata', () {
      final options = PendingPracticeOptions(
        initialQuestionCount: 12,
        initialQuestionCountsBySection: {'1A': 7, '1B': 5},
      );
      final config = PracticeSessionConfig.pending(options: options);

      expect(options.batchSize, 10);
      expect(options.loadThreshold, 5);
      expect(options.initialQuestionCount, 12);
      expect(options.initialQuestionCountsBySection, {'1A': 7, '1B': 5});
      expect(config.pendingOptions, same(options));
    });

    test('defensively copies counts and supports value equality', () {
      final counts = {'1A': 2};
      final options = PendingPracticeOptions(
        initialQuestionCount: 2,
        initialQuestionCountsBySection: counts,
      );
      final equalOptions = PendingPracticeOptions(
        initialQuestionCount: 2,
        initialQuestionCountsBySection: const {'1A': 2},
      );

      counts['1A'] = 99;

      expect(options.initialQuestionCountsBySection, {'1A': 2});
      expect(
        () => options.initialQuestionCountsBySection['1B'] = 1,
        throwsUnsupportedError,
      );
      expect(options, equalOptions);
      expect(options.hashCode, equalOptions.hashCode);
      expect(
        PracticeSessionConfig.pending(options: options),
        PracticeSessionConfig.pending(options: equalOptions),
      );
    });

    test('validates batching and display metadata at runtime', () {
      expect(() => PendingPracticeOptions(batchSize: 0), throwsArgumentError);
      expect(
        () => PendingPracticeOptions(loadThreshold: -1),
        throwsArgumentError,
      );
      expect(
        () => PendingPracticeOptions(initialQuestionCount: -1),
        throwsArgumentError,
      );
      expect(
        () => PendingPracticeOptions(
          initialQuestionCountsBySection: const {'1A': -1},
        ),
        throwsArgumentError,
      );
      expect(
        () => PendingPracticeOptions(
          initialQuestionCount: 2,
          initialQuestionCountsBySection: const {'1A': 1},
        ),
        throwsArgumentError,
      );
    });
  });
}
