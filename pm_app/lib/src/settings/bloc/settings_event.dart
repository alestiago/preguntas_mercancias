part of 'settings_bloc.dart';

@immutable
sealed class SettingsEvent {
  const SettingsEvent();
}

final class AnswerShuffleToggled extends SettingsEvent {
  const AnswerShuffleToggled(this.enabled);

  final bool enabled;
}

final class _AnswerShuffleEnabledChanged extends SettingsEvent {
  const _AnswerShuffleEnabledChanged(this.answerShuffleEnabled);

  final bool answerShuffleEnabled;
}

final class _SettingsObservationFailed extends SettingsEvent {
  const _SettingsObservationFailed(this.error);

  final Object error;
}
