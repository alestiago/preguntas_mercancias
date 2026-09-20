import 'package:pm_questions/pm_questions.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

List<Question> buildQuestions() {
  return [
    Question(
      code: '1A01001',
      section: '1A',
      prompt: 'Primera pregunta',
      answers: _answers,
      correctOption: QuestionOption.b,
      norma: 'Norma primera',
    ),
    Question(
      code: '1A01002',
      section: '1A',
      prompt: 'Segunda pregunta',
      answers: _answers,
      correctOption: QuestionOption.a,
      norma: 'Norma segunda',
    ),
  ];
}

List<Question> buildHomeQuestions() {
  return [
    ...buildQuestions(),
    Question(
      code: '1A01003',
      section: '1A',
      prompt: 'Tercera pregunta',
      answers: _answers,
      correctOption: QuestionOption.d,
      norma: 'Norma tercera',
    ),
  ];
}

Question buildLongQuestion() {
  return Question(
    code: '1A01999',
    section: '1A',
    prompt: List.filled(
      12,
      'Pregunta larga para comprobar que el contenido puede desplazarse.',
    ).join(' '),
    answers: const [
      QuestionAnswer(
        option: QuestionOption.a,
        text: 'Respuesta A con suficiente texto para ocupar varias lineas.',
      ),
      QuestionAnswer(
        option: QuestionOption.b,
        text: 'Respuesta B con suficiente texto para ocupar varias lineas.',
      ),
      QuestionAnswer(
        option: QuestionOption.c,
        text: 'Respuesta C con suficiente texto para ocupar varias lineas.',
      ),
      QuestionAnswer(
        option: QuestionOption.d,
        text: 'Respuesta D con suficiente texto para ocupar varias lineas.',
      ),
    ],
    correctOption: QuestionOption.a,
    norma: 'Norma larga',
  );
}

List<Question> buildReviewQuestions() {
  return [
    Question(
      code: '1A01001',
      section: '1A',
      prompt: 'Pregunta 1A',
      answers: _answers,
      correctOption: QuestionOption.b,
      norma: 'Norma primera',
    ),
    Question(
      code: '1B01001',
      section: '1B',
      prompt: 'Pregunta 1B',
      answers: _answers,
      correctOption: QuestionOption.b,
      norma: 'Norma segunda',
    ),
  ];
}

Future<List<Question>> loadReviewQuestions(String? section) async {
  final questions = buildReviewQuestions();
  return section == null
      ? questions
      : questions
            .where((question) => question.section == section)
            .toList(growable: false);
}

List<Question> buildManyQuestions(int count) {
  return List<Question>.generate(count, (index) {
    final questionNumber = index + 1;
    return Question(
      code: '1A${questionNumber.toString().padLeft(5, '0')}',
      section: '1A',
      prompt: 'Pregunta $questionNumber',
      answers: _answers,
      correctOption: QuestionOption.a,
      norma: 'Norma',
    );
  });
}

List<Question> buildSimulacroQuestions() {
  return [
    for (final section in questionBankManifest.sections)
      for (var questionNumber = 1; questionNumber <= 8; questionNumber += 1)
        Question(
          code: '$section${questionNumber.toString().padLeft(5, '0')}',
          section: section,
          prompt: '$section pregunta $questionNumber',
          answers: _answers,
          correctOption: QuestionOption.a,
          norma: 'Norma',
        ),
  ];
}

const _answers = [
  QuestionAnswer(option: QuestionOption.a, text: 'Respuesta A'),
  QuestionAnswer(option: QuestionOption.b, text: 'Respuesta B'),
  QuestionAnswer(option: QuestionOption.c, text: 'Respuesta C'),
  QuestionAnswer(option: QuestionOption.d, text: 'Respuesta D'),
];
