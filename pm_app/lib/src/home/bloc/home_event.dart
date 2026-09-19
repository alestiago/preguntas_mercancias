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

final class HomeProgressRefreshed extends HomeReadRequested {
  const HomeProgressRefreshed();
}

final class _HomeProgressSnapshotChanged extends HomeEvent {
  const _HomeProgressSnapshotChanged(this.progressSnapshot);

  final QuestionProgressSnapshot progressSnapshot;
}
