part of 'settings_bloc.dart';

@immutable
sealed class SettingsEvent {
  const SettingsEvent();
}

final class AnswerShuffleToggled extends SettingsEvent {
  const AnswerShuffleToggled(this.enabled);

  final bool enabled;
}

/// The user finished or skipped first-launch onboarding.
final class OnboardingCompleted extends SettingsEvent {
  const OnboardingCompleted();
}

final class _SettingsObservationRequested extends SettingsEvent {
  const _SettingsObservationRequested();
}
