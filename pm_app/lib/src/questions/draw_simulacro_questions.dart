import 'dart:math';

import 'package:pm_questions/pm_questions.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

const simulacroQuestionCount = 30;

List<Question> drawSimulacroQuestions(
  List<Question> questions, {
  Random? random,
}) {
  final randomSource = random ?? Random();
  final questionPoolsBySection = _shuffledQuestionPoolsBySection(
    questions,
    random: randomSource,
  );
  if (questionPoolsBySection.isEmpty) {
    return const <Question>[];
  }

  final totalAvailableQuestions = questionPoolsBySection.values.fold<int>(
    0,
    (total, questions) => total + questions.length,
  );
  final targetQuestionCount = min(
    simulacroQuestionCount,
    totalAvailableQuestions,
  );
  final sectionOrder = questionPoolsBySection.keys.toList()
    ..shuffle(randomSource);
  final questionsPerSection = targetQuestionCount ~/ sectionOrder.length;
  var extraQuestionCount = targetQuestionCount % sectionOrder.length;
  var remainingQuestionCount = targetQuestionCount;
  final selectedQuestions = <Question>[];

  for (final section in sectionOrder) {
    final questionPool = questionPoolsBySection[section]!;
    final sectionQuestionCount =
        questionsPerSection + (extraQuestionCount > 0 ? 1 : 0);
    if (extraQuestionCount > 0) {
      extraQuestionCount -= 1;
    }

    final takeCount = min(sectionQuestionCount, questionPool.length);
    selectedQuestions.addAll(questionPool.take(takeCount));
    questionPoolsBySection[section] = questionPool.skip(takeCount).toList();
    remainingQuestionCount -= takeCount;
  }

  while (remainingQuestionCount > 0) {
    final sectionsWithQuestions =
        sectionOrder
            .where((section) => questionPoolsBySection[section]!.isNotEmpty)
            .toList()
          ..shuffle(randomSource);
    if (sectionsWithQuestions.isEmpty) {
      break;
    }

    for (final section in sectionsWithQuestions) {
      if (remainingQuestionCount == 0) {
        break;
      }

      selectedQuestions.add(questionPoolsBySection[section]!.removeLast());
      remainingQuestionCount -= 1;
    }
  }

  selectedQuestions.shuffle(randomSource);
  return List<Question>.unmodifiable(selectedQuestions);
}

Map<String, List<Question>> _shuffledQuestionPoolsBySection(
  List<Question> questions, {
  Random? random,
}) {
  final randomSource = random ?? Random();
  final questionPoolsBySection = <String, List<Question>>{};

  for (final section in QuestionBankLoader.sections) {
    final questionPool = questions
        .where((question) => question.section == section)
        .toList();
    if (questionPool.isEmpty) {
      continue;
    }

    questionPoolsBySection[section] = questionPool..shuffle(randomSource);
  }

  return questionPoolsBySection;
}
