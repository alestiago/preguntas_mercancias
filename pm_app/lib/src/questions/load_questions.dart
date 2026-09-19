import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions/pm_questions.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import 'pending_question_batch.dart';

typedef LoadQuestions = Future<List<Question>> Function(String? section);
typedef LoadMoreQuestions =
    Future<PendingQuestionBatch> Function(
      String? section,
      Set<String> loadedQuestionCodes,
      QuestionProgressSnapshot progressSnapshot,
    );

Future<List<Question>> loadQuestionsFromBank(String? section) {
  final loader = QuestionBankLoader();
  return section == null ? loader.loadAll() : loader.loadSection(section);
}
