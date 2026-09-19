import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:pm_persistence/pm_persistence.dart';

final class ProgressResetCubit extends Cubit<ProgressResetState> {
  ProgressResetCubit({required this.questionProgressStore})
    : super(const ProgressResetIdle());

  final QuestionProgressStore questionProgressStore;

  Future<void> reset() async {
    // A repeated confirmation while the first clear is pending must not issue
    // another destructive write.
    if (state is ProgressResetInProgress) {
      return;
    }

    emit(const ProgressResetInProgress());
    try {
      await questionProgressStore.clear();
      if (!isClosed) {
        emit(const ProgressResetSuccess());
      }
    } catch (error) {
      if (!isClosed) {
        emit(ProgressResetFailure(error));
      }
    }
  }
}

@immutable
sealed class ProgressResetState extends Equatable {
  const ProgressResetState();
}

final class ProgressResetIdle extends ProgressResetState {
  const ProgressResetIdle();

  @override
  List<Object?> get props => const [ProgressResetIdle];
}

final class ProgressResetInProgress extends ProgressResetState {
  const ProgressResetInProgress();

  @override
  List<Object?> get props => const [ProgressResetInProgress];
}

final class ProgressResetSuccess extends ProgressResetState {
  const ProgressResetSuccess();

  @override
  List<Object?> get props => const [ProgressResetSuccess];
}

final class ProgressResetFailure extends ProgressResetState {
  const ProgressResetFailure(this.error);

  final Object error;

  @override
  List<Object?> get props => [ProgressResetFailure, error];
}
