import '../models/models.dart';

abstract interface class QuestionProgressStore {
  Future<QuestionProgressSnapshot> loadSnapshot();

  Stream<QuestionProgressSnapshot> watchSnapshot();

  Future<void> recordAnswer(QuestionAnswerRecord answer);

  Future<void> clear();

  Future<void> close();
}
