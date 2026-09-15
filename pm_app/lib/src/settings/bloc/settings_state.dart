part of 'settings_bloc.dart';

@immutable
sealed class SettingsState {
  const SettingsState();

  bool get answerShuffleEnabled => true;
}

final class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

final class SettingsLoadFailure extends SettingsState {
  const SettingsLoadFailure(this.error);

  final Object error;
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
}
