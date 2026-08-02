part of 'home_bloc.dart';

@immutable
sealed class HomeEvent {
  const HomeEvent();
}

final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

final class HomeRetried extends HomeEvent {
  const HomeRetried();
}

final class HomeProgressRefreshed extends HomeEvent {
  const HomeProgressRefreshed();
}

final class _HomeProgressSnapshotChanged extends HomeEvent {
  const _HomeProgressSnapshotChanged(this.progressSnapshot);

  final QuestionProgressSnapshot progressSnapshot;
}
