import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions/pm_questions.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import 'pending_question_batch.dart';

typedef LoadQuestions = Future<List<Question>> Function(String? section);
typedef LoadQuestionCatalog = Future<QuestionCatalog> Function();
typedef LoadMoreQuestions =
    Future<PendingQuestionBatch> Function(
      String? section,
      Set<String> loadedQuestionCodes,
      QuestionProgressSnapshot progressSnapshot,
    );

Future<QuestionCatalog> loadQuestionCatalogFromBank() {
  return QuestionBankLoader().loadCatalog();
}

LoadQuestionCatalog cacheQuestionCatalog(LoadQuestionCatalog loadCatalog) {
  Future<QuestionCatalog>? cachedLoad;

  return () {
    final existingLoad = cachedLoad;
    if (existingLoad != null) {
      return existingLoad;
    }

    late final Future<QuestionCatalog> newLoad;
    newLoad = Future<QuestionCatalog>.sync(loadCatalog).then(
      (catalog) => catalog,
      onError: (Object error, StackTrace stackTrace) {
        if (identical(cachedLoad, newLoad)) {
          cachedLoad = null;
        }
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
    cachedLoad = newLoad;
    return newLoad;
  };
}

LoadQuestions loadQuestionsFromCatalog(QuestionCatalog catalog) {
  return (section) async {
    if (section == null) {
      return catalog.questions;
    }

    final normalizedSection = section.trim().toUpperCase();
    final questions = catalog.bySection[normalizedSection];
    if (questions == null) {
      throw ArgumentError.value(
        section,
        'section',
        'Expected one of: ${catalog.bySection.keys.join(', ')}.',
      );
    }
    return questions;
  };
}

final LoadQuestionCatalog _defaultCatalogLoader = cacheQuestionCatalog(
  loadQuestionCatalogFromBank,
);

Future<List<Question>> loadQuestionsFromBank(String? section) async {
  final catalog = await _defaultCatalogLoader();
  return loadQuestionsFromCatalog(catalog)(section);
}
