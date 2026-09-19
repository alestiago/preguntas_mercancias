import 'package:pm_questions/question_ingestion.dart';
import 'package:test/test.dart';

import '../../matchers/matchers.dart';

void main() {
  test('decodes and encodes a valid question', () async {
    final question = await QuestionJsonCodec.decode(_validQuestionJson());

    expect(
      question,
      isAQuestion(
        code: '1A01001',
        section: '1A',
        correctOption: QuestionOption.b,
        correctAnswer: isAQuestionAnswer(text: 'Correcta'),
      ),
    );
    expect(QuestionJsonCodec.encode(question), _validQuestionJson());
  });

  test('defaults shuffleable to true when absent', () async {
    final question = await QuestionJsonCodec.decode(_validQuestionJson());

    expect(question.shuffleable, isTrue);
  });

  test('reads an explicit shuffleable value', () async {
    final json = _validQuestionJson()..['shuffleable'] = false;

    final question = await QuestionJsonCodec.decode(json);

    expect(question.shuffleable, isFalse);
    expect(QuestionJsonCodec.encode(question)['shuffleable'], isFalse);
  });

  test('rejects missing required fields', () async {
    final json = _validQuestionJson()..remove('prompt');

    await expectLater(
      QuestionJsonCodec.decode(json),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('prompt'),
        ),
      ),
    );
  });

  test('rejects duplicate answer options', () async {
    final json = _validQuestionJson();
    final answers = json['answers']! as List<Map<String, Object?>>;
    answers[3]['option'] = 'A';
    answers[3]['text'] = 'Duplicada';

    await expectLater(
      QuestionJsonCodec.decode(json),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          allOf(contains('at most 1'), contains('at least 1')),
        ),
      ),
    );
  });

  test('rejects blank answer text', () async {
    final json = _validQuestionJson();
    final answers = json['answers']! as List<Map<String, Object?>>;
    answers[0]['text'] = '   ';

    await expectLater(
      QuestionJsonCodec.decode(json),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('pattern'),
        ),
      ),
    );
  });
}

Map<String, Object?> _validQuestionJson() {
  final answers = <Map<String, Object?>>[
    {'option': 'A', 'text': 'Incorrecta'},
    {'option': 'B', 'text': 'Correcta'},
    {'option': 'C', 'text': 'Incorrecta'},
    {'option': 'D', 'text': 'Incorrecta'},
  ];

  return {
    'code': '1A01001',
    'section': '1A',
    'prompt': 'Pregunta de ejemplo',
    'answers': answers,
    'correctOption': 'B',
    'norma': 'Código Civil, art. 1543',
  };
}
