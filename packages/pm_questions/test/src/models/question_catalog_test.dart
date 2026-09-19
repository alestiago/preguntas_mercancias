import 'package:pm_questions/pm_questions.dart';
import 'package:test/test.dart';

void main() {
  test('preserves order and builds code and section indexes', () {
    final first = _question(code: '1B00001', section: '1B');
    final second = _question(code: '1A00001', section: '1A');
    final third = _question(code: '1B00002', section: '1B');

    final catalog = QuestionCatalog([first, second, third]);

    expect(catalog.questions, [first, second, third]);
    expect(catalog.byCode, {
      first.code: first,
      second.code: second,
      third.code: third,
    });
    expect(catalog.bySection.keys, ['1B', '1A']);
    expect(catalog.bySection['1B'], [first, third]);
    expect(catalog.bySection['1A'], [second]);
  });

  test('rejects duplicate question codes', () {
    expect(
      () => QuestionCatalog([
        _question(code: '1A00001', section: '1A'),
        _question(code: '1A00001', section: '1B'),
      ]),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains('duplicate question code 1A00001'),
        ),
      ),
    );
  });

  test('defensively freezes the ordered questions and indexes', () {
    final first = _question(code: '1A00001', section: '1A');
    final source = [first];
    final catalog = QuestionCatalog(source);

    source.add(_question(code: '1A00002', section: '1A'));

    expect(catalog.questions, [first]);
    expect(() => catalog.questions.clear(), throwsUnsupportedError);
    expect(() => catalog.byCode.clear(), throwsUnsupportedError);
    expect(() => catalog.bySection.clear(), throwsUnsupportedError);
    expect(() => catalog.bySection['1A']!.clear(), throwsUnsupportedError);
  });

  test('uses value equality', () {
    expect(
      QuestionCatalog([_question(code: '1A00001', section: '1A')]),
      QuestionCatalog([_question(code: '1A00001', section: '1A')]),
    );
  });
}

Question _question({required String code, required String section}) {
  return Question(
    code: code,
    section: section,
    prompt: 'Prompt $code',
    answers: const [
      QuestionAnswer(option: QuestionOption.a, text: 'A'),
      QuestionAnswer(option: QuestionOption.b, text: 'B'),
      QuestionAnswer(option: QuestionOption.c, text: 'C'),
      QuestionAnswer(option: QuestionOption.d, text: 'D'),
    ],
    correctOption: QuestionOption.a,
    norma: 'Norma',
  );
}
