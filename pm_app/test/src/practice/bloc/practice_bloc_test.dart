import 'dart:async';

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
              state.questions.length == 1 &&
              state.currentQuestion.prompt == 'Primera pregunta' &&
              !state.answered,
        );
        bloc.add(const NextQuestionPressed());
        final looped = await loopedFuture as PracticeLoaded;

        expect(looped.progress, 1);

        final completedFuture = bloc.stream.firstWhere(
          (state) =>
              state is PracticeLoaded &&
              state.answered &&
              !state.isRecordingAnswer &&
              state.isReviewComplete,
        );
        bloc.add(const AnswerPressed(QuestionOption.b));
        final completed = await completedFuture as PracticeLoaded;

        expect(completed.correctCount, 2);
        expect(completed.incorrectCount, 1);
      },
    );
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
