import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

typedef LoadQuestions = Future<List<Question>> Function(String? section);
typedef LoadMoreQuestions =
    Future<List<Question>> Function(
      String? section,
      Set<String> loadedQuestionCodes,
      QuestionProgressSnapshot progressSnapshot,
    );

Future<List<Question>> loadQuestionsFromBank(String? section) {
  final loader = QuestionBankLoader();
  return section == null ? loader.loadAll() : loader.loadSection(section);
}
