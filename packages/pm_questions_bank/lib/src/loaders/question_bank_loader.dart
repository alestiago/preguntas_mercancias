import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:pm_questions/question_ingestion.dart';

import '../../question_bank_manifest.dart';

final class QuestionBankLoader {
  QuestionBankLoader({AssetBundle? assetBundle})
    : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;

  Future<QuestionCatalog> loadCatalog() async {
    return QuestionCatalog(await loadAll());
  }

  Future<List<Question>> loadAll() async {
    final questionsBySection = await Future.wait(
      questionBankManifest.sections.map(loadSection),
    );
    final questions = [
      for (final sectionQuestions in questionsBySection) ...sectionQuestions,
    ];

    return List.unmodifiable(questions);
  }

  Future<List<Question>> loadSection(String section) async {
    final assetPath = questionBankManifest.runtimeAssetPath(section);

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
