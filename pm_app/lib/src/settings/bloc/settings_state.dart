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
  const SettingsLoaded({required this.answerShuffleEnabled});

  @override
  final bool answerShuffleEnabled;

  SettingsLoaded copyWith({bool? answerShuffleEnabled}) {
    return SettingsLoaded(
      answerShuffleEnabled: answerShuffleEnabled ?? this.answerShuffleEnabled,
    );
  }

  @override
  List<Object?> get props => [SettingsLoaded, answerShuffleEnabled];
}
