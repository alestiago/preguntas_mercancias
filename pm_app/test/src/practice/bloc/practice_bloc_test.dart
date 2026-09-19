import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/practice/bloc/practice_bloc.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../../helpers/fake_question_progress_store.dart';

void main() {
  group('PracticeBloc', () {
    test('loads questions and records an answer', () async {
      final progressStore = FakeQuestionProgressStore();
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => _questions,
        questionProgressStore: progressStore,
      );
      addTearDown(bloc.close);

      final loadedFuture = bloc.stream.firstWhere(
        (state) => state is PracticeLoaded,
      );
      bloc.add(const PracticeStarted());
      final loaded = await loadedFuture as PracticeLoaded;

      expect(loaded.questions, hasLength(2));
      expect(loaded.currentQuestion.prompt, 'Primera pregunta');
      expect(loaded.correctCount, 0);
      expect(loaded.incorrectCount, 0);

      final answeredFuture = bloc.stream.firstWhere(
        (state) =>
            state is PracticeLoaded &&
            state.answered &&
            state.progressSnapshot.answeredQuestionCount == 1,
      );
      bloc.add(const AnswerPressed(QuestionOption.b));
      final answered = await answeredFuture as PracticeLoaded;

      expect(answered.selectedOption, QuestionOption.b);
      expect(answered.correctCount, 1);
      expect(answered.incorrectCount, 0);
      expect(progressStore.recordedAnswers, hasLength(1));
      expect(progressStore.recordedAnswers.single.questionCode, '1A01001');
    });

    test('shuffles answer presentation for loaded questions', () async {
      final progressStore = FakeQuestionProgressStore();
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => [_questions.first],
        questionProgressStore: progressStore,
        answerShuffleRandom: Random(1),
      );
      addTearDown(bloc.close);

      final loadedFuture = bloc.stream.firstWhere(
        (state) => state is PracticeLoaded,
      );
      bloc.add(const PracticeStarted());
      final loaded = await loadedFuture as PracticeLoaded;
      final loadedQuestion = loaded.currentQuestion;

      expect(loadedQuestion.correctOption, QuestionOption.b);
      expect(
        loadedQuestion.answers.map((answer) => answer.option),
        isNot([
          QuestionOption.a,
          QuestionOption.b,
          QuestionOption.c,
          QuestionOption.d,
        ]),
      );
      expect(
        loadedQuestion.answers.indexWhere(
          (answer) => answer.option == QuestionOption.b,
        ),
        isNot(1),
      );
    });

    test('keeps original answer order when shuffling is disabled', () async {
      final progressStore = FakeQuestionProgressStore();
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => [_questions.first],
        questionProgressStore: progressStore,
        answerShuffleRandom: Random(1),
        shuffleAnswers: false,
      );
      addTearDown(bloc.close);

      final loadedFuture = bloc.stream.firstWhere(
        (state) => state is PracticeLoaded,
      );
      bloc.add(const PracticeStarted());
      final loaded = await loadedFuture as PracticeLoaded;

      expect(loaded.currentQuestion.answers.map((answer) => answer.option), [
        QuestionOption.a,
        QuestionOption.b,
        QuestionOption.c,
        QuestionOption.d,
      ]);
    });

    test(
      'keeps original answer order for a non-shuffleable question',
      () async {
        final progressStore = FakeQuestionProgressStore();
        addTearDown(progressStore.close);
        final nonShuffleableQuestion = Question(
          code: '1A01003',
          section: '1A',
          prompt: 'Tercera pregunta',
          answers: const [
            QuestionAnswer(option: QuestionOption.a, text: 'Respuesta A'),
            QuestionAnswer(option: QuestionOption.b, text: 'Respuesta B'),
            QuestionAnswer(option: QuestionOption.c, text: 'Respuesta C'),
            QuestionAnswer(
              option: QuestionOption.d,
              text: 'Las respuestas A y B son correctas',
            ),
          ],
          correctOption: QuestionOption.d,
          norma: 'Norma tercera',
          shuffleable: false,
        );
        final bloc = PracticeBloc(
          loadQuestions: (_) async => [nonShuffleableQuestion],
          questionProgressStore: progressStore,
          answerShuffleRandom: Random(1),
        );
        addTearDown(bloc.close);

        final loadedFuture = bloc.stream.firstWhere(
          (state) => state is PracticeLoaded,
        );
        bloc.add(const PracticeStarted());
        final loaded = await loadedFuture as PracticeLoaded;

        expect(loaded.currentQuestion.answers.map((answer) => answer.option), [
          QuestionOption.a,
          QuestionOption.b,
          QuestionOption.c,
          QuestionOption.d,
        ]);
      },
    );

    test('advances after answering', () async {
      final progressStore = FakeQuestionProgressStore();
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => _questions,
        questionProgressStore: progressStore,
      );
      addTearDown(bloc.close);

      final loadedFuture = bloc.stream.firstWhere(
        (state) => state is PracticeLoaded,
      );
      bloc.add(const PracticeStarted());
      await loadedFuture;

      final answeredFuture = bloc.stream.firstWhere(
        (state) =>
            state is PracticeLoaded &&
            state.answered &&
            state.progressSnapshot.answeredQuestionCount == 1,
      );
      bloc.add(const AnswerPressed(QuestionOption.b));
      await answeredFuture;

      final advancedFuture = bloc.stream.firstWhere(
        (state) =>
            state is PracticeLoaded &&
            state.currentIndex == 1 &&
            !state.answered,
      );
      bloc.add(const NextQuestionPressed());
      final advanced = await advancedFuture as PracticeLoaded;

      expect(advanced.currentQuestion.prompt, 'Segunda pregunta');
      expect(advanced.correctCount, 1);
      expect(advanced.incorrectCount, 0);
    });

    test('does not advance while an answer is being recorded', () async {
      final progressStore = SlowQuestionProgressStore();
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => _questions,
        questionProgressStore: progressStore,
      );
      addTearDown(bloc.close);

      final loadedFuture = bloc.stream.firstWhere(
        (state) => state is PracticeLoaded,
      );
      bloc.add(const PracticeStarted());
      await loadedFuture;

      final recordingFuture = bloc.stream.firstWhere(
        (state) => state is PracticeLoaded && state.isRecordingAnswer,
      );
      bloc.add(const AnswerPressed(QuestionOption.b));
      final recording = await recordingFuture as PracticeLoaded;

      expect(recording.answered, isTrue);
      expect(recording.currentIndex, 0);

      bloc.add(const NextQuestionPressed());
      await Future<void>.delayed(Duration.zero);

      expect((bloc.state as PracticeLoaded).currentIndex, 0);

      progressStore.completePendingRecords();

      final recordedFuture = bloc.stream.firstWhere(
        (state) =>
            state is PracticeLoaded &&
            state.answered &&
            !state.isRecordingAnswer,
      );
      await recordedFuture;

      final advancedFuture = bloc.stream.firstWhere(
        (state) => state is PracticeLoaded && state.currentIndex == 1,
      );
      bloc.add(const NextQuestionPressed());
      final advanced = await advancedFuture as PracticeLoaded;

      expect(advanced.currentQuestion.prompt, 'Segunda pregunta');
    });

    test('skips ahead without answering', () async {
      final progressStore = FakeQuestionProgressStore();
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => _questions,
        questionProgressStore: progressStore,
      );
      addTearDown(bloc.close);

      final loadedFuture = bloc.stream.firstWhere(
        (state) => state is PracticeLoaded,
      );
      bloc.add(const PracticeStarted());
      await loadedFuture;

      final skippedFuture = bloc.stream.firstWhere(
        (state) =>
            state is PracticeLoaded &&
            state.currentIndex == 1 &&
            !state.answered,
      );
      bloc.add(const NextQuestionPressed());
      final skipped = await skippedFuture as PracticeLoaded;

      expect(skipped.currentQuestion.prompt, 'Segunda pregunta');
      expect(skipped.correctCount, 0);
      expect(skipped.incorrectCount, 0);
      expect(progressStore.recordedAnswers, isEmpty);
    });

    test('goes back to a skipped question and can still answer it', () async {
      final progressStore = FakeQuestionProgressStore();
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => _questions,
        questionProgressStore: progressStore,
      );
      addTearDown(bloc.close);

      final loadedFuture = bloc.stream.firstWhere(
        (state) => state is PracticeLoaded,
      );
      bloc.add(const PracticeStarted());
      await loadedFuture;

      final skippedFuture = bloc.stream.firstWhere(
        (state) => state is PracticeLoaded && state.currentIndex == 1,
      );
      bloc.add(const NextQuestionPressed());
      await skippedFuture;

      final backFuture = bloc.stream.firstWhere(
        (state) =>
            state is PracticeLoaded &&
            state.currentIndex == 0 &&
            !state.answered,
      );
      bloc.add(const PreviousQuestionPressed());
      await backFuture;

      final answeredFuture = bloc.stream.firstWhere(
        (state) =>
            state is PracticeLoaded &&
            state.answered &&
            !state.isRecordingAnswer,
      );
      bloc.add(const AnswerPressed(QuestionOption.b));
      final answered = await answeredFuture as PracticeLoaded;

      expect(answered.currentQuestion.prompt, 'Primera pregunta');
      expect(answered.selectedOption, QuestionOption.b);
    });

    test(
      'remembers each question\'s own answer when navigating back',
      () async {
        final progressStore = FakeQuestionProgressStore();
        addTearDown(progressStore.close);
        final bloc = PracticeBloc(
          loadQuestions: (_) async => _questions,
          questionProgressStore: progressStore,
        );
        addTearDown(bloc.close);

        final loadedFuture = bloc.stream.firstWhere(
          (state) => state is PracticeLoaded,
        );
        bloc.add(const PracticeStarted());
        await loadedFuture;

        final firstAnsweredFuture = bloc.stream.firstWhere(
          (state) =>
              state is PracticeLoaded &&
              state.answered &&
              !state.isRecordingAnswer,
        );
        bloc.add(const AnswerPressed(QuestionOption.b));
        await firstAnsweredFuture;

        final advancedFuture = bloc.stream.firstWhere(
          (state) => state is PracticeLoaded && state.currentIndex == 1,
        );
        bloc.add(const NextQuestionPressed());
        await advancedFuture;

        expect((bloc.state as PracticeLoaded).answered, isFalse);

        final backFuture = bloc.stream.firstWhere(
          (state) =>
              state is PracticeLoaded &&
              state.currentIndex == 0 &&
              state.answered,
        );
        bloc.add(const PreviousQuestionPressed());
        final back = await backFuture as PracticeLoaded;

        expect(back.selectedOption, QuestionOption.b);
      },
    );

    test('does not go back past the first question', () async {
      final progressStore = FakeQuestionProgressStore();
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => _questions,
        questionProgressStore: progressStore,
      );
      addTearDown(bloc.close);

      final loadedFuture = bloc.stream.firstWhere(
        (state) => state is PracticeLoaded,
      );
      bloc.add(const PracticeStarted());
      await loadedFuture;

      bloc.add(const PreviousQuestionPressed());
      await Future<void>.delayed(Duration.zero);

      expect((bloc.state as PracticeLoaded).currentIndex, 0);
    });

    test('jumps directly to a selected question', () async {
      final progressStore = FakeQuestionProgressStore();
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => _questions,
        questionProgressStore: progressStore,
        isSimulacroMode: true,
      );
      addTearDown(bloc.close);

      final loadedFuture = bloc.stream.firstWhere(
        (state) => state is PracticeLoaded,
      );
      bloc.add(const PracticeStarted());
      final loaded = await loadedFuture as PracticeLoaded;

      expect(loaded.isQuestionDrawerNavigationEnabled, isTrue);

      final jumpedFuture = bloc.stream.firstWhere(
        (state) => state is PracticeLoaded && state.currentIndex == 1,
      );
      bloc.add(const QuestionNavigationPressed(1));
      final jumped = await jumpedFuture as PracticeLoaded;

      expect(jumped.currentQuestion.prompt, 'Segunda pregunta');
    });

    test('ignores question navigation with an invalid index', () async {
      final progressStore = FakeQuestionProgressStore();
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => _questions,
        questionProgressStore: progressStore,
      );
      addTearDown(bloc.close);

      final loadedFuture = bloc.stream.firstWhere(
        (state) => state is PracticeLoaded,
      );
      bloc.add(const PracticeStarted());
      await loadedFuture;

      bloc.add(const QuestionNavigationPressed(12));
      await Future<void>.delayed(Duration.zero);

      expect((bloc.state as PracticeLoaded).currentIndex, 0);
    });

    test(
      'ignores question navigation while an answer is being recorded',
      () async {
        final progressStore = SlowQuestionProgressStore();
        addTearDown(progressStore.close);
        final bloc = PracticeBloc(
          loadQuestions: (_) async => _questions,
          questionProgressStore: progressStore,
        );
        addTearDown(bloc.close);

        final loadedFuture = bloc.stream.firstWhere(
          (state) => state is PracticeLoaded,
        );
        bloc.add(const PracticeStarted());
        await loadedFuture;

        final recordingFuture = bloc.stream.firstWhere(
          (state) => state is PracticeLoaded && state.isRecordingAnswer,
        );
        bloc.add(const AnswerPressed(QuestionOption.b));
        await recordingFuture;

        bloc.add(const QuestionNavigationPressed(1));
        await Future<void>.delayed(Duration.zero);

        expect((bloc.state as PracticeLoaded).currentIndex, 0);

        final recordedFuture = bloc.stream.firstWhere(
          (state) =>
              state is PracticeLoaded &&
              state.answered &&
              !state.isRecordingAnswer,
        );
        progressStore.completePendingRecords();
        await recordedFuture;
      },
    );

    test(
      'requires the last question to be answered before advancing further',
      () async {
        final progressStore = FakeQuestionProgressStore();
        addTearDown(progressStore.close);
        final bloc = PracticeBloc(
          loadQuestions: (_) async => _questions,
          questionProgressStore: progressStore,
          isSimulacroMode: true,
        );
        addTearDown(bloc.close);

        final loadedFuture = bloc.stream.firstWhere(
          (state) => state is PracticeLoaded,
        );
        bloc.add(const PracticeStarted());
        await loadedFuture;

        final lastFuture = bloc.stream.firstWhere(
          (state) => state is PracticeLoaded && state.currentIndex == 1,
        );
        bloc.add(const NextQuestionPressed());
        final last = await lastFuture as PracticeLoaded;

        expect(last.isLastQuestion, isTrue);
        expect(last.answered, isFalse);

        bloc.add(const NextQuestionPressed());
        await Future<void>.delayed(Duration.zero);

        final unchanged = bloc.state as PracticeLoaded;
        expect(unchanged.currentIndex, 1);
        expect(unchanged.answered, isFalse);
      },
    );

    test(
      'review mode loops remaining questions until all are correct',
      () async {
        final progressStore = FakeQuestionProgressStore();
        addTearDown(progressStore.close);
        await progressStore.recordAnswer(
          QuestionAnswerRecord(
            questionCode: '1A01001',
            section: '1A',
            selectedOption: QuestionOption.a,
            correctOption: QuestionOption.b,
          ),
        );
        await progressStore.recordAnswer(
          QuestionAnswerRecord(
            questionCode: '1A01002',
            section: '1A',
            selectedOption: QuestionOption.b,
            correctOption: QuestionOption.a,
          ),
        );
        final bloc = PracticeBloc(
          loadQuestions: (_) async => _questions,
          questionProgressStore: progressStore,
          initialSection: null,
          isReviewMode: true,
        );
        addTearDown(bloc.close);

        final loadedFuture = bloc.stream.firstWhere(
          (state) => state is PracticeLoaded,
        );
        bloc.add(const PracticeStarted());
        final loaded = await loadedFuture as PracticeLoaded;

        expect(loaded.questions, hasLength(2));
        expect(loaded.isReviewMode, isTrue);

        final firstAnsweredFuture = bloc.stream.firstWhere(
          (state) =>
              state is PracticeLoaded &&
              state.answered &&
              !state.isRecordingAnswer &&
              state.incorrectCount == 1,
        );
        bloc.add(const AnswerPressed(QuestionOption.a));
        await firstAnsweredFuture;

        final advancedFuture = bloc.stream.firstWhere(
          (state) =>
              state is PracticeLoaded &&
              state.currentQuestion.prompt == 'Segunda pregunta' &&
              !state.answered,
        );
        bloc.add(const NextQuestionPressed());
        await advancedFuture;

        final secondAnsweredFuture = bloc.stream.firstWhere(
          (state) =>
              state is PracticeLoaded &&
              state.answered &&
              !state.isRecordingAnswer &&
              state.correctCount == 1,
        );
        bloc.add(const AnswerPressed(QuestionOption.a));
        await secondAnsweredFuture;

        final loopedFuture = bloc.stream.firstWhere(
          (state) =>
              state is PracticeLoaded &&
              state.remainingFilteredQuestions.length == 1 &&
              state.currentQuestion.prompt == 'Primera pregunta' &&
              !state.answered,
        );
        bloc.add(const NextQuestionPressed());
        final looped = await loopedFuture as PracticeLoaded;

        expect(looped.questions, hasLength(2));

        final completedFuture = bloc.stream.firstWhere(
          (state) =>
              state is PracticeLoaded &&
              state.answered &&
              !state.isRecordingAnswer &&
              state.isFilteredPracticeComplete,
        );
        bloc.add(const AnswerPressed(QuestionOption.b));
        final completed = await completedFuture as PracticeLoaded;

        expect(completed.correctCount, 2);
        expect(completed.incorrectCount, 1);
      },
    );

    test(
      'review mode allows repeated attempts at one incorrect question',
      () async {
        final progressStore = FakeQuestionProgressStore();
        addTearDown(progressStore.close);
        await progressStore.recordAnswer(
          QuestionAnswerRecord(
            questionCode: '1A01001',
            section: '1A',
            selectedOption: QuestionOption.a,
            correctOption: QuestionOption.b,
          ),
        );
        final bloc = PracticeBloc(
          loadQuestions: (_) async => [_questions.first],
          questionProgressStore: progressStore,
          isReviewMode: true,
        );
        addTearDown(bloc.close);

        final loadedFuture = bloc.stream.firstWhere(
          (state) => state is PracticeLoaded,
        );
        bloc.add(const PracticeStarted());
        await loadedFuture;

        for (var attempt = 1; attempt <= 2; attempt += 1) {
          final answeredFuture = bloc.stream.firstWhere(
            (state) =>
                state is PracticeLoaded &&
                state.incorrectCount == attempt &&
                state.answered &&
                !state.isRecordingAnswer,
          );
          bloc.add(const AnswerPressed(QuestionOption.a));
          await answeredFuture;

          final reopenedFuture = bloc.stream.firstWhere(
            (state) =>
                state is PracticeLoaded &&
                state.incorrectCount == attempt &&
                !state.answered,
          );
          bloc.add(const NextQuestionPressed());
          await reopenedFuture;
        }

        final completedFuture = bloc.stream.firstWhere(
          (state) =>
              state is PracticeLoaded &&
              state.correctCount == 1 &&
              state.incorrectCount == 2 &&
              state.answered &&
              !state.isRecordingAnswer &&
              state.isFilteredPracticeComplete,
        );
        bloc.add(const AnswerPressed(QuestionOption.b));
        await completedFuture;

        expect(progressStore.recordedAnswers, hasLength(4));
        expect(
          progressStore.recordedAnswers.map((answer) => answer.selectedOption),
          [
            QuestionOption.a,
            QuestionOption.a,
            QuestionOption.a,
            QuestionOption.b,
          ],
        );
      },
    );

    test(
      'pending mode loops remaining unanswered questions until all are answered',
      () async {
        final progressStore = FakeQuestionProgressStore();
        addTearDown(progressStore.close);
        final bloc = PracticeBloc(
          loadQuestions: (_) async => _questions,
          questionProgressStore: progressStore,
          initialSection: null,
          isPendingMode: true,
        );
        addTearDown(bloc.close);

        final loadedFuture = bloc.stream.firstWhere(
          (state) => state is PracticeLoaded,
        );
        bloc.add(const PracticeStarted());
        final loaded = await loadedFuture as PracticeLoaded;

        expect(loaded.questions, hasLength(2));
        expect(loaded.isPendingMode, isTrue);

        final firstAnsweredFuture = bloc.stream.firstWhere(
          (state) =>
              state is PracticeLoaded &&
              state.answered &&
              !state.isRecordingAnswer &&
              state.incorrectCount == 1,
        );
        bloc.add(const AnswerPressed(QuestionOption.a));
        await firstAnsweredFuture;

        final advancedFuture = bloc.stream.firstWhere(
          (state) =>
              state is PracticeLoaded &&
              state.remainingFilteredQuestions.length == 1 &&
              state.currentQuestion.prompt == 'Segunda pregunta' &&
              !state.answered,
        );
        bloc.add(const NextQuestionPressed());
        await advancedFuture;

        final completedFuture = bloc.stream.firstWhere(
          (state) =>
              state is PracticeLoaded &&
              state.answered &&
              !state.isRecordingAnswer &&
              state.isFilteredPracticeComplete,
        );
        bloc.add(const AnswerPressed(QuestionOption.a));
        final completed = await completedFuture as PracticeLoaded;

        expect(completed.correctCount, 1);
        expect(completed.incorrectCount, 1);
      },
    );

    test('pending mode loads more questions when five remain', () async {
      final progressStore = FakeQuestionProgressStore();
      final questions = _manyQuestions(15);
      final loadMoreCalls = <Set<String>>[];
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => questions.take(10).toList(growable: false),
        loadMoreQuestions: (_, loadedQuestionCodes, progressSnapshot) async {
          loadMoreCalls.add({...loadedQuestionCodes});
          return questions
              .where(
                (question) =>
                    !loadedQuestionCodes.contains(question.code) &&
                    progressSnapshot.progressFor(question.code) == null,
              )
              .take(10)
              .toList(growable: false);
        },
        questionProgressStore: progressStore,
        initialSection: null,
        isPendingMode: true,
      );
      addTearDown(bloc.close);

      final loadedFuture = bloc.stream.firstWhere(
        (state) => state is PracticeLoaded,
      );
      bloc.add(const PracticeStarted());
      final loaded = await loadedFuture as PracticeLoaded;

      expect(loaded.questions, hasLength(10));

      for (var answeredCount = 1; answeredCount < 5; answeredCount += 1) {
        final answeredFuture = bloc.stream.firstWhere(
          (state) =>
              state is PracticeLoaded &&
              state.answered &&
              !state.isRecordingAnswer &&
              state.progressSnapshot.answeredQuestionCount == answeredCount,
        );
        bloc.add(const AnswerPressed(QuestionOption.a));
        await answeredFuture;

        final advancedFuture = bloc.stream.firstWhere(
          (state) =>
              state is PracticeLoaded &&
              !state.answered &&
              state.currentQuestion.prompt == 'Pregunta ${answeredCount + 1}',
        );
        bloc.add(const NextQuestionPressed());
        await advancedFuture;
      }

      expect(loadMoreCalls, isEmpty);

      final refilledFuture = bloc.stream.firstWhere(
        (state) =>
            state is PracticeLoaded &&
            state.questions.length == 15 &&
            state.progressSnapshot.answeredQuestionCount == 5,
      );
      bloc.add(const AnswerPressed(QuestionOption.a));
      final refilled = await refilledFuture as PracticeLoaded;

      expect(loadMoreCalls, hasLength(1));
      expect(loadMoreCalls.single, contains('1A00010'));
      // The full, stable set of already-loaded codes is passed (including
      // answered ones) so the caller never re-fetches a duplicate.
      expect(loadMoreCalls.single, contains('1A00001'));
      expect(refilled.remainingFilteredQuestions, hasLength(10));
      expect(
        refilled.remainingFilteredQuestions.map((question) => question.prompt),
        contains('Pregunta 15'),
      );
    });
  });
}

final class SlowQuestionProgressStore extends FakeQuestionProgressStore {
  final List<Completer<void>> _pendingRecords = [];

  @override
  Future<void> recordAnswer(QuestionAnswerRecord answer) async {
    final completer = Completer<void>();
    _pendingRecords.add(completer);
    await completer.future;
    await super.recordAnswer(answer);
  }

  void completePendingRecords() {
    for (final completer in _pendingRecords) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }
}

final _questions = [
  Question(
    code: '1A01001',
    section: '1A',
    prompt: 'Primera pregunta',
    answers: const [
      QuestionAnswer(option: QuestionOption.a, text: 'Respuesta A'),
      QuestionAnswer(option: QuestionOption.b, text: 'Respuesta B'),
      QuestionAnswer(option: QuestionOption.c, text: 'Respuesta C'),
      QuestionAnswer(option: QuestionOption.d, text: 'Respuesta D'),
    ],
    correctOption: QuestionOption.b,
    norma: 'Norma primera',
  ),
  Question(
    code: '1A01002',
    section: '1A',
    prompt: 'Segunda pregunta',
    answers: const [
      QuestionAnswer(option: QuestionOption.a, text: 'Respuesta A'),
      QuestionAnswer(option: QuestionOption.b, text: 'Respuesta B'),
      QuestionAnswer(option: QuestionOption.c, text: 'Respuesta C'),
      QuestionAnswer(option: QuestionOption.d, text: 'Respuesta D'),
    ],
    correctOption: QuestionOption.a,
    norma: 'Norma segunda',
  ),
];

List<Question> _manyQuestions(int count) {
  return List<Question>.generate(count, (index) {
    final questionNumber = index + 1;
    return Question(
      code: '1A${questionNumber.toString().padLeft(5, '0')}',
      section: '1A',
      prompt: 'Pregunta $questionNumber',
      answers: const [
        QuestionAnswer(option: QuestionOption.a, text: 'Respuesta A'),
        QuestionAnswer(option: QuestionOption.b, text: 'Respuesta B'),
        QuestionAnswer(option: QuestionOption.c, text: 'Respuesta C'),
        QuestionAnswer(option: QuestionOption.d, text: 'Respuesta D'),
      ],
      correctOption: QuestionOption.a,
      norma: 'Norma',
    );
  });
}
