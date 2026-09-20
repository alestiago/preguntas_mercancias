import 'package:pm_app/component_library.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions/pm_questions.dart';

abstract final class WidgetbookFixtures {
  static final DateTime _answerTime = DateTime.utc(2026, 9, 20, 12, 30);

  static Question question({
    int index = 1,
    String section = '1A',
    String? prompt,
    QuestionOption correctOption = QuestionOption.c,
  }) {
    return Question(
      code: '$section-${index.toString().padLeft(3, '0')}',
      section: section,
      prompt: prompt ?? '¿Qué documentación debe acompañar a la mercancía durante el transporte?',
      answers: const [
        QuestionAnswer(
          option: QuestionOption.a,
          text: 'Únicamente la factura comercial.',
        ),
        QuestionAnswer(
          option: QuestionOption.b,
          text: 'Una autorización verbal del expedidor.',
        ),
        QuestionAnswer(
          option: QuestionOption.c,
          text: 'La documentación exigida por la normativa aplicable.',
        ),
        QuestionAnswer(
          option: QuestionOption.d,
          text: 'Ningún documento cuando el trayecto sea nacional.',
        ),
      ],
      correctOption: correctOption,
      norma: 'Ley 16/1987, artículo 47',
      doctrinalReference: 'Referencia de ejemplo para Widgetbook.',
    );
  }

  static HomeLoaded homeProgress({
    required int correctCount,
    required int incorrectCount,
    required int unansweredCount,
  }) {
    final questions = <Question>[];
    final progress = <String, QuestionProgress>{};
    var index = 1;

    for (var count = 0; count < correctCount; count += 1) {
      final item = question(index: index++);
      questions.add(item);
      progress[item.code] = _progress(item, isCorrect: true);
    }
    for (var count = 0; count < incorrectCount; count += 1) {
      final item = question(index: index++);
      questions.add(item);
      progress[item.code] = _progress(item, isCorrect: false);
    }
    for (var count = 0; count < unansweredCount; count += 1) {
      questions.add(question(index: index++));
    }

    return HomeLoaded(
      catalog: QuestionCatalog(questions),
      progressSnapshot: QuestionProgressSnapshot(byQuestionCode: progress),
    );
  }

  static AnswerHistorySection historySection({
    required DateTime date,
    int entryCount = 3,
    bool includeMissingQuestion = false,
  }) {
    final entries = <AnswerHistoryEntry>[];
    for (var index = 1; index <= entryCount; index += 1) {
      final item = question(index: index);
      final selectedOption = index.isEven
          ? item.correctOption
          : QuestionOption.a;
      entries.add(
        AnswerHistoryEntry(
          answer: QuestionAnswerRecord(
            questionCode: item.code,
            section: item.section,
            selectedOption: selectedOption,
            correctOption: item.correctOption,
            answeredAt: date.add(Duration(hours: 8 + index)),
          ),
          question: includeMissingQuestion && index == entryCount ? null : item,
        ),
      );
    }
    return AnswerHistorySection(date: date, entries: entries);
  }

  static QuestionProgress _progress(
    Question question, {
    required bool isCorrect,
  }) {
    return QuestionProgress(
      questionCode: question.code,
      section: question.section,
      lastSelectedOption: isCorrect ? question.correctOption : QuestionOption.a,
      correctOption: question.correctOption,
      lastAnswerWasCorrect: isCorrect,
      attempts: 1,
      correctAttempts: isCorrect ? 1 : 0,
      incorrectAttempts: isCorrect ? 0 : 1,
      firstAnsweredAt: _answerTime,
      lastAnsweredAt: _answerTime,
    );
  }
}
