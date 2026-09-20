import 'package:flutter_test/flutter_test.dart';
import 'package:pm_questions_bank/question_bank_manifest.dart';

void main() {
  test('defines the edition and ordered sections once', () {
    expect(questionBankManifest.edition, 'pm_260326');
    expect(questionBankManifest.sections, [
      '1A',
      '1B',
      '1C',
      '1D',
      '1E',
      '1F',
      '1G',
      '1H',
    ]);
  });

  test('derives source, output, and runtime paths', () {
    expect(
      questionBankManifest.sourceAssetPath(' 1a '),
      'assets/pm_260326/pm1A.txt',
    );
    expect(
      questionBankManifest.outputAssetPath('1A'),
      'assets/pm_260326_json/pm1A.json',
    );
    expect(
      questionBankManifest.runtimeAssetPath('1A'),
      'packages/pm_questions_bank/assets/pm_260326_json/pm1A.json',
    );
    expect(
      questionBankManifest.nonShuffleableCodesPath,
      'assets/pm_260326/non_shuffleable.txt',
    );
  });

  test('rejects unknown sections', () {
    expect(
      () => questionBankManifest.runtimeAssetPath('2A'),
      throwsArgumentError,
    );
  });
}
