import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/practice/bloc/practice_bloc.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

void main() {
  group('PracticeBloc', () {
    test('loads questions and records an answer', () async {
      final bloc = PracticeBloc(loadQuestions: (_) async => _questions);
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
        (state) => state is PracticeLoaded && state.answered,
      );
      bloc.add(const AnswerPressed(QuestionOption.b));
      final answered = await answeredFuture as PracticeLoaded;

      expect(answered.selectedOption, QuestionOption.b);
      expect(answered.correctCount, 1);
      expect(answered.incorrectCount, 0);
    });

    test('advances after answering', () async {
      final bloc = PracticeBloc(loadQuestions: (_) async => _questions);
      addTearDown(bloc.close);

      final loadedFuture = bloc.stream.firstWhere(
        (state) => state is PracticeLoaded,
      );
      bloc.add(const PracticeStarted());
      await loadedFuture;

      final answeredFuture = bloc.stream.firstWhere(
        (state) => state is PracticeLoaded && state.answered,
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
  });
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
