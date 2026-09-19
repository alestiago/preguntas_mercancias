import 'package:flutter_test/flutter_test.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../matchers/matchers.dart';

void main() {
  test('offers explicit strict and nullable canonical answer lookups', () {
    final question = Question(
      code: '1A01001',
      section: '1A',
      prompt: 'Pregunta',
      answers: const [
        QuestionAnswer(option: QuestionOption.a, text: 'Respuesta A'),
      ],
      correctOption: QuestionOption.a,
      norma: 'Norma',
    );

    expect(question.answerFor(QuestionOption.a).text, 'Respuesta A');
    expect(question.answerForOrNull(QuestionOption.b), isNull);
    expect(() => question.answerFor(QuestionOption.b), throwsStateError);
  });

  group('Question.fromJson', () {
    test('creates a question from valid JSON', () async {
      final question = await Question.fromJson(_validQuestionJson());

      expect(
        question,
        isAQuestion(
          code: '1A01001',
          section: '1A',
          correctOption: QuestionOption.b,
          correctAnswer: isAQuestionAnswer(text: 'Correcta'),
        ),
      );
      expect(question.isCorrect(QuestionOption.b), isTrue);
      expect(question.isCorrect(QuestionOption.a), isFalse);
    });

    test('defaults shuffleable to true when absent', () async {
      final question = await Question.fromJson(_validQuestionJson());

      expect(question.shuffleable, isTrue);
    });

    test('reads an explicit shuffleable value', () async {
      final json = _validQuestionJson()..['shuffleable'] = false;

      final question = await Question.fromJson(json);

      expect(question.shuffleable, isFalse);
    });

    test('rejects missing required fields', () async {
      final json = _validQuestionJson()..remove('prompt');

      await expectLater(
        Question.fromJson(json),
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
        Question.fromJson(json),
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
        Question.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('pattern'),
          ),
        ),
      );
    });
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
