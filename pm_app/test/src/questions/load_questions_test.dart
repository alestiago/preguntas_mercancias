import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/questions/load_questions.dart';
import 'package:pm_questions/pm_questions.dart';

import '../../fixtures/question_fixtures.dart';

void main() {
  test('shares concurrent loads and caches a successful catalog', () async {
    final sourceLoad = Completer<QuestionCatalog>();
    var loadCount = 0;
    final loadCatalog = cacheQuestionCatalog(() {
      loadCount += 1;
      return sourceLoad.future;
    });

    final firstLoad = loadCatalog();
    final concurrentLoad = loadCatalog();

    expect(loadCount, 1);
    expect(identical(firstLoad, concurrentLoad), isTrue);

    final catalog = QuestionCatalog(buildQuestions());
    sourceLoad.complete(catalog);

    expect(await firstLoad, same(catalog));
    expect(await loadCatalog(), same(catalog));
    expect(loadCount, 1);
  });

  test('clears a failed load so a later call can retry', () async {
    var loadCount = 0;
    final catalog = QuestionCatalog(buildQuestions());
    final loadCatalog = cacheQuestionCatalog(() async {
      loadCount += 1;
      if (loadCount == 1) {
        throw StateError('First load failed.');
      }
      return catalog;
    });

    await expectLater(loadCatalog(), throwsStateError);

    expect(await loadCatalog(), same(catalog));
    expect(loadCount, 2);
  });

  test('creates section loaders from the catalog indexes', () async {
    final catalog = QuestionCatalog(buildQuestions());
    final loadQuestions = loadQuestionsFromCatalog(catalog);

    expect(await loadQuestions(null), same(catalog.questions));
    expect(await loadQuestions(' 1a '), same(catalog.bySection['1A']));
    await expectLater(loadQuestions('missing'), throwsArgumentError);
  });
}
