import 'package:flutter/services.dart';

import '../models/models.dart';
import '../parsers/parsers.dart';

final class QuestionBankLoader {
  QuestionBankLoader({
    AssetBundle? assetBundle,
    QuestionTxtParser parser = const QuestionTxtParser(),
  }) : _assetBundle = assetBundle ?? rootBundle,
       _parser = parser;

  static const sections = ['1A', '1B', '1C', '1D', '1E', '1F', '1G', '1H'];

  static const _assetPathBySection = {
    '1A': 'packages/pm_questions_bank/assets/pm_260326/pm1A.txt',
    '1B': 'packages/pm_questions_bank/assets/pm_260326/pm1B.txt',
    '1C': 'packages/pm_questions_bank/assets/pm_260326/pm1C.txt',
    '1D': 'packages/pm_questions_bank/assets/pm_260326/pm1D.txt',
    '1E': 'packages/pm_questions_bank/assets/pm_260326/pm1E.txt',
    '1F': 'packages/pm_questions_bank/assets/pm_260326/pm1F.txt',
    '1G': 'packages/pm_questions_bank/assets/pm_260326/pm1G.txt',
    '1H': 'packages/pm_questions_bank/assets/pm_260326/pm1H.txt',
  };

  final AssetBundle _assetBundle;
  final QuestionTxtParser _parser;

  Future<List<Question>> loadAll() async {
    final questions = <Question>[];

    for (final section in sections) {
      questions.addAll(await loadSection(section));
    }

    return List.unmodifiable(questions);
  }

  Future<List<Question>> loadSection(String section) async {
    final normalizedSection = section.trim().toUpperCase();
    final assetPath = _assetPathBySection[normalizedSection];

    if (assetPath == null) {
      throw ArgumentError.value(
        section,
        'section',
        'Expected one of: ${sections.join(', ')}.',
      );
    }

    final source = await _assetBundle.loadString(assetPath);
    return _parser.parse(source);
  }
}
