import '../models/models.dart';

abstract interface class QuestionProgressStore {
  Future<QuestionProgressSnapshot> loadSnapshot();

  /// Emits the current snapshot on subscription, then every observed change.
  ///
  /// Errors from the underlying storage are emitted on the stream. Changes
  /// made through another store are observable when both stores share the
  /// same underlying database.
  Stream<QuestionProgressSnapshot> watchSnapshot();

  Future<List<QuestionAnswerRecord>> loadAnswerHistory();

  /// Emits the current history on subscription, then every observed change.
  ///
  /// Errors and cross-store visibility follow [watchSnapshot].
  Stream<List<QuestionAnswerRecord>> watchAnswerHistory();

  Future<void> recordAnswer(QuestionAnswerRecord answer);

  Future<void> clear();

  Future<void> close();
}
