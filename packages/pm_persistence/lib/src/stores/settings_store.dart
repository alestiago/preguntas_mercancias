/// Persistent application settings.
///
/// Future-returning operations surface storage failures to their caller.
/// Watch operations surface failures as stream errors. The component that
/// creates a store owns it and must call [close] after all consumers have
/// stopped listening; injected feature state objects must not close the store.
abstract interface class SettingsStore {
  /// Loads the current answer-shuffle preference.
  ///
  /// Implementations return their documented default when no value was saved.
  Future<bool> loadAnswerShuffleEnabled();

  /// Emits the current value on subscription, then successful writes made
  /// through this store instance.
  ///
  /// Read and write failures are emitted or returned as errors. Changes made
  /// outside this store instance are not observed automatically.
  Stream<bool> watchAnswerShuffleEnabled();

  /// Persists [enabled] before emitting it to watchers.
  Future<void> setAnswerShuffleEnabled(bool enabled);

  /// Releases resources owned by this store.
  ///
  /// Consumers must cancel subscriptions and stop using the store first.
  Future<void> close();
}
