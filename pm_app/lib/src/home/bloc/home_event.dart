part of 'home_bloc.dart';

@immutable
sealed class HomeEvent {
  const HomeEvent();
}

sealed class HomeReadRequested extends HomeEvent {
  const HomeReadRequested();
}

final class HomeStarted extends HomeReadRequested {
  const HomeStarted();
}

final class HomeRetried extends HomeReadRequested {
  const HomeRetried();
}

final class _HomeProgressSnapshotChanged extends HomeEvent {
  const _HomeProgressSnapshotChanged(this.progressSnapshot);

  final QuestionProgressSnapshot progressSnapshot;
}

final class _HomeProgressObservationFailed extends HomeEvent {
  const _HomeProgressObservationFailed(this.error);

  final Object error;
}
