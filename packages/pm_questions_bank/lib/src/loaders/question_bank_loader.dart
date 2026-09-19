import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:pm_questions/question_ingestion.dart';

final class QuestionBankLoader {
  QuestionBankLoader({AssetBundle? assetBundle})
    : _assetBundle = assetBundle ?? rootBundle;

  static const sections = ['1A', '1B', '1C', '1D', '1E', '1F', '1G', '1H'];

  static const _assetPathBySection = {
    '1A': 'packages/pm_questions_bank/assets/pm_260326_json/pm1A.json',
    '1B': 'packages/pm_questions_bank/assets/pm_260326_json/pm1B.json',
    '1C': 'packages/pm_questions_bank/assets/pm_260326_json/pm1C.json',
    '1D': 'packages/pm_questions_bank/assets/pm_260326_json/pm1D.json',
    '1E': 'packages/pm_questions_bank/assets/pm_260326_json/pm1E.json',
    '1F': 'packages/pm_questions_bank/assets/pm_260326_json/pm1F.json',
    '1G': 'packages/pm_questions_bank/assets/pm_260326_json/pm1G.json',
    '1H': 'packages/pm_questions_bank/assets/pm_260326_json/pm1H.json',
  };

  final AssetBundle _assetBundle;

  Future<QuestionCatalog> loadCatalog() async {
    return QuestionCatalog(await loadAll());
  }

  Future<List<Question>> loadAll() async {
    final questionsBySection = await Future.wait(sections.map(loadSection));
    final questions = [
      for (final sectionQuestions in questionsBySection) ...sectionQuestions,
    ];

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
    final json = jsonDecode(source);
    if (json is! List<Object?>) {
      throw FormatException('Expected a list of questions in $assetPath.');
    }

    final questions = <Question>[];
    for (final rawQuestion in json) {
      if (rawQuestion is! Map<String, Object?>) {
        throw FormatException('Expected a question object in $assetPath.');
      }

      questions.add(await QuestionJsonCodec.decode(rawQuestion));
    }

    return List.unmodifiable(questions);
  }
}
