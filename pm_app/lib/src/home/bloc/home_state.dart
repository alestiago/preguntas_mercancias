part of 'home_bloc.dart';

@immutable
sealed class HomeState {
  const HomeState();
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class HomeLoadFailure extends HomeState {
  const HomeLoadFailure(this.error);

  final Object error;
}

final class HomeLoaded extends HomeState {
  HomeLoaded({
    required Set<String> questionCodes,
    required this.progressSnapshot,
  }) : questionCodes = Set.unmodifiable(questionCodes);

  final Set<String> questionCodes;
  final QuestionProgressSnapshot progressSnapshot;

  int get totalQuestionCount => questionCodes.length;

  int get correctQuestionCount {
    return _knownProgress.where((progress) {
      return progress.correctAttempts > 0;
    }).length;
  }

  int get incorrectQuestionCount {
    return _knownProgress.where((progress) {
      return progress.correctAttempts == 0;
    }).length;
  }

  int get unansweredQuestionCount {
    return totalQuestionCount - correctQuestionCount - incorrectQuestionCount;
  }

  Iterable<QuestionProgress> get _knownProgress {
    return questionCodes
        .map(progressSnapshot.progressFor)
        .whereType<QuestionProgress>();
  }

  HomeLoaded copyWith({QuestionProgressSnapshot? progressSnapshot}) {
    return HomeLoaded(
      questionCodes: questionCodes,
      progressSnapshot: progressSnapshot ?? this.progressSnapshot,
    );
  }
}
