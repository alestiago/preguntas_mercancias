abstract interface class SettingsStore {
  Future<bool> loadAnswerShuffleEnabled();

  /// Emits the current value on subscription, then successful writes made
  /// through this store instance.
  ///
  /// Read and write failures are emitted or returned as errors. Changes made
  /// outside this store instance are not observed automatically.
  Stream<bool> watchAnswerShuffleEnabled();

  Future<void> setAnswerShuffleEnabled(bool enabled);

  Future<void> close();
}
