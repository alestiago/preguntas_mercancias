import 'package:pm_questions/pm_questions.dart';
import 'package:test/test.dart';

void main() {
  test('offers explicit strict and nullable canonical answer lookups', () {
    final question = _question();

    expect(question.answerFor(QuestionOption.a).text, 'Respuesta A');
    expect(question.answerForOrNull(QuestionOption.a)?.text, 'Respuesta A');
    expect(question.isCorrect(QuestionOption.b), isTrue);
  });

  test('defensively copies answers', () {
    final answers = _answers();
    final question = _question(answers: answers);

    answers.clear();

    expect(question.answers, hasLength(4));
    expect(() => question.answers.clear(), throwsUnsupportedError);
  });

  test('supports value equality', () {
    expect(_question(), _question());
    expect(_question().hashCode, _question().hashCode);
  });

  test('rejects a missing answer option', () {
    expect(() => _question(answers: _answers().take(3)), throwsArgumentError);
  });

  test('rejects duplicate answer options', () {
    final answers = _answers()..[3] = _answers().first;

    expect(() => _question(answers: answers), throwsArgumentError);
  });

  test('rejects blank domain fields and answer text', () {
    expect(() => _question(prompt: '   '), throwsArgumentError);
    expect(
      () => _question(
        answers: [
          const QuestionAnswer(option: QuestionOption.a, text: '   '),
          ..._answers().skip(1),
        ],
      ),
      throwsArgumentError,
    );
  });
}

Question _question({
  String prompt = 'Pregunta',
  Iterable<QuestionAnswer>? answers,
}) {
  return Question(
    code: '1A01001',
    section: '1A',
    prompt: prompt,
    answers: answers ?? _answers(),
    correctOption: QuestionOption.b,
    norma: 'Norma',
  );
}

List<QuestionAnswer> _answers() {
  return [
    for (final option in QuestionOption.values)
      QuestionAnswer(option: option, text: 'Respuesta ${option.code}'),
  ];
}
