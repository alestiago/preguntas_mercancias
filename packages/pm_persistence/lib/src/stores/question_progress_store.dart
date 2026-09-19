import '../models/models.dart';

/// Durable question-attempt and aggregate-progress storage.
///
/// Future-returning operations surface storage failures to their caller.
/// Watch operations surface failures as stream errors. The component that
/// creates a store owns it and must call [close] after all consumers have
/// stopped listening; injected feature state objects must not close the store.
abstract interface class QuestionProgressStore {
  /// Loads the current immutable aggregate progress snapshot.
  Future<QuestionProgressSnapshot> loadSnapshot();

  /// Emits the current snapshot on subscription, then every observed change.
  ///
  /// Errors from the underlying storage are emitted on the stream. Changes
  /// made through another store are observable when both stores share the
  /// same underlying database.
  Stream<QuestionProgressSnapshot> watchSnapshot();

  /// Loads at most [limit] immutable answer attempts, newest first.
  ///
  /// Equal timestamps are ordered by newest insertion first. The returned
  /// page reports whether increasing [limit] can reveal older attempts. Callers
  /// must not use the relative order of equal timestamps as record identity.
  Future<QuestionAnswerHistoryPage> loadAnswerHistory({required int limit});

  /// Emits a bounded history prefix on subscription and observed changes.
  ///
  /// Ordering, errors, and cross-store visibility follow
  /// [loadAnswerHistory] and [watchSnapshot].
  Stream<QuestionAnswerHistoryPage> watchAnswerHistory({required int limit});

  /// Atomically appends [answer] and updates its aggregate question progress.
  Future<void> recordAnswer(QuestionAnswerRecord answer);

  /// Removes all answer attempts and aggregate question progress.
  Future<void> clear();

  /// Releases resources owned by this store.
  ///
  /// Consumers must cancel subscriptions and stop using the store first.
  Future<void> close();
}
