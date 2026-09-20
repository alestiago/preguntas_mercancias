import 'package:pm_questions/pm_questions.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

typedef LoadQuestionCatalog = Future<QuestionCatalog> Function();

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
