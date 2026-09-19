import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_questions/pm_questions.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads questions by section from bundled assets', () async {
    final questions = await QuestionBankLoader().loadSection('1A');

    expect(questions, isNotEmpty);
    expect(questions.first.code, '1A01001');
    expect(questions.first.section, '1A');
    expect(questions.first.answers, hasLength(4));
    expect(questions.first.correctOption, QuestionOption.b);
  });

  test('loads every bundled question file', () async {
    final questions = await QuestionBankLoader().loadAll();

    expect(questions, hasLength(4475));
    expect(questions.map((question) => question.section).toSet(), {
      '1A',
      '1B',
      '1C',
      '1D',
      '1E',
      '1F',
      '1G',
      '1H',
    });
  });

  test('rejects unknown sections', () async {
    await expectLater(
      QuestionBankLoader(assetBundle: _EmptyAssetBundle()).loadSection('2A'),
      throwsArgumentError,
    );
  });
}

final class _EmptyAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    throw StateError('Unexpected asset load: $key');
  }
}
