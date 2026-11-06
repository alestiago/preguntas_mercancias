part of 'settings_bloc.dart';

@immutable
sealed class SettingsState extends Equatable {
  const SettingsState();

  bool get answerShuffleEnabled => true;

  @override
  List<Object?> get props => const [];
}

final class SettingsLoading extends SettingsState {
  const SettingsLoading();

  @override
  List<Object?> get props => const [SettingsLoading];
}

final class SettingsLoadFailure extends SettingsState {
  const SettingsLoadFailure(this.error);

  final Object error;

  @override
  List<Object?> get props => [SettingsLoadFailure, error];
}

final class SettingsLoaded extends SettingsState {
  const SettingsLoaded({
    required this.answerShuffleEnabled,
    this.onboardingCompleted = true,
  });

  @override
  final bool answerShuffleEnabled;

  /// Whether first-launch onboarding was finished or skipped.
  ///
  /// When the stored flag can't be read, this is `true` so that a storage
  /// failure never keeps the user out of the app.
  final bool onboardingCompleted;

  SettingsLoaded copyWith({
    bool? answerShuffleEnabled,
    bool? onboardingCompleted,
  }) {
    return SettingsLoaded(
      answerShuffleEnabled: answerShuffleEnabled ?? this.answerShuffleEnabled,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  @override
  List<Object?> get props => [
    SettingsLoaded,
    answerShuffleEnabled,
    onboardingCompleted,
  ];
}
