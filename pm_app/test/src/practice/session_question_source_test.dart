import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/practice/practice_launch.dart';
import 'package:pm_app/src/practice/practice_session_config.dart';
import 'package:pm_app/src/practice/session_question_source.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions/pm_questions.dart';

import '../../fixtures/question_fixtures.dart';

void main() {
  group('SessionQuestionRequest', () {
    test('is defensively immutable and validates requested size', () {
      final excludedCodes = <String>{'1A00001'};
      final request = SessionQuestionRequest(
        section: '1A',
        excludedQuestionCodes: excludedCodes,
        progressSnapshot: const QuestionProgressSnapshot.empty(),
        requestedSize: 10,
      );

      excludedCodes.add('1A00002');

      expect(request.excludedQuestionCodes, {'1A00001'});
      expect(
        () => request.excludedQuestionCodes.add('1A00003'),
        throwsUnsupportedError,
      );
      expect(
        () => SessionQuestionRequest(
          section: null,
          excludedQuestionCodes: const {},
          progressSnapshot: const QuestionProgressSnapshot.empty(),
          requestedSize: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('CatalogSessionQuestionSource', () {
    test(
      'uses current progress, section, exclusions, and requested size',
      () async {
        final questions = buildManyQuestions(5);
        final source = CatalogSessionQuestionSource(
          catalog: QuestionCatalog(questions),
          mode: PracticeMode.pending,
        );
        final progress = QuestionProgressSnapshot(
          byQuestionCode: {
            questions.first.code: _answeredProgress(questions.first),
          },
        );

        final batch = await source.load(
          SessionQuestionRequest(
            section: '1A',
            excludedQuestionCodes: {questions[1].code},
            progressSnapshot: progress,
            requestedSize: 2,
          ),
        );

        expect(batch.questions.map((question) => question.code), [
          questions[2].code,
          questions[3].code,
        ]);
        expect(batch.hasMore, isTrue);
      },
    );

    test('reports initial pending exhaustion accurately', () async {
      final questions = buildManyQuestions(2);
      final source = CatalogSessionQuestionSource(
        catalog: QuestionCatalog(questions),
        mode: PracticeMode.pending,
      );

      final batch = await source.load(
        SessionQuestionRequest(
          section: null,
          excludedQuestionCodes: const {},
          progressSnapshot: const QuestionProgressSnapshot.empty(),
          requestedSize: 10,
        ),
      );

      expect(batch.questions, questions);
      expect(batch.hasMore, isFalse);
    });

    test('returns a complete non-pending selection', () async {
      final questions = buildQuestions();
      final source = CatalogSessionQuestionSource(
        catalog: QuestionCatalog(questions),
        mode: PracticeMode.standard,
      );

      final batch = await source.load(
        SessionQuestionRequest(
          section: '1A',
          excludedQuestionCodes: const {},
          progressSnapshot: const QuestionProgressSnapshot.empty(),
          requestedSize: 1,
        ),
      );

      expect(batch.questions, questions);
      expect(batch.hasMore, isFalse);
    });

    test('normalizes known sections and rejects unknown sections', () async {
      final source = CatalogSessionQuestionSource(
        catalog: QuestionCatalog(buildQuestions()),
        mode: PracticeMode.standard,
      );

      final batch = await source.load(
        SessionQuestionRequest(
          section: ' 1a ',
          excludedQuestionCodes: const {},
          progressSnapshot: const QuestionProgressSnapshot.empty(),
          requestedSize: null,
        ),
      );

      expect(batch.questions, hasLength(2));
      await expectLater(
        source.load(
          SessionQuestionRequest(
            section: 'missing',
            excludedQuestionCodes: const {},
            progressSnapshot: const QuestionProgressSnapshot.empty(),
            requestedSize: null,
          ),
        ),
        throwsArgumentError,
      );
    });
  });

  test(
    'fixed sources freeze their questions and are always complete',
    () async {
      final questions = buildQuestions();
      final source = FixedSessionQuestionSource(
        questions: questions,
        mode: PracticeMode.simulacro,
      );
      questions.clear();

      final batch = await source.load(
        SessionQuestionRequest(
          section: '9Z',
          excludedQuestionCodes: const {'1A01001'},
          progressSnapshot: const QuestionProgressSnapshot.empty(),
          requestedSize: 1,
        ),
      );

      expect(batch.questions, hasLength(2));
      expect(batch.hasMore, isFalse);
      expect(() => batch.questions.clear(), throwsUnsupportedError);
    },
  );

  group('PracticeLaunchFactory', () {
    test('builds matching sources for all five modes', () {
      final catalog = QuestionCatalog(buildQuestions());
      final question = catalog.questions.first;
      final launches = [
        practiceLaunchFactory.standard(catalog: catalog, shuffleAnswers: false),
        practiceLaunchFactory.review(catalog: catalog, shuffleAnswers: false),
        practiceLaunchFactory.pending(
          catalog: catalog,
          shuffleAnswers: false,
          options: PendingPracticeOptions(
            initialQuestionCount: 2,
            initialQuestionCountsBySection: const {'1A': 2},
          ),
        ),
        practiceLaunchFactory.simulacro(
          questions: catalog.questions,
          shuffleAnswers: false,
        ),
        practiceLaunchFactory.singleQuestion(
          question: question,
          shuffleAnswers: false,
        ),
      ];

      expect(launches.map((launch) => launch.config.mode), PracticeMode.values);
      for (final launch in launches) {
        expect(launch.source.mode, launch.config.mode);
      }
    });

    test('rejects a mismatched configuration and source', () {
      final fixedSource = FixedSessionQuestionSource(
        questions: buildQuestions(),
        mode: PracticeMode.simulacro,
      );

      expect(
        () => PracticeLaunch(
          config: const PracticeSessionConfig.singleQuestion(),
          source: fixedSource,
        ),
        throwsArgumentError,
      );
    });
  });
}

QuestionProgress _answeredProgress(Question question) {
  final answeredAt = DateTime.utc(2026);
  return QuestionProgress(
    questionCode: question.code,
    section: question.section,
    lastSelectedOption: question.correctOption,
    correctOption: question.correctOption,
    lastAnswerWasCorrect: true,
    attempts: 1,
    correctAttempts: 1,
    incorrectAttempts: 0,
    firstAnsweredAt: answeredAt,
    lastAnsweredAt: answeredAt,
  );
}
