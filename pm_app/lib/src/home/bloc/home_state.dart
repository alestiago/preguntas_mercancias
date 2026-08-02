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
    required List<Question> questions,
    required this.progressSnapshot,
  }) : questions = List.unmodifiable(questions);

  final List<Question> questions;
  final QuestionProgressSnapshot progressSnapshot;

  Set<String> get questionCodes {
    return Set.unmodifiable(questions.map((question) => question.code));
  }

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
      questions: questions,
      progressSnapshot: progressSnapshot ?? this.progressSnapshot,
    );
  }
}
