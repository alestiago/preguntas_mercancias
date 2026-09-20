part of 'home_bloc.dart';

@immutable
sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => const [];
}

final class HomeLoading extends HomeState {
  const HomeLoading();

  @override
  List<Object?> get props => const [HomeLoading];
}

final class HomeLoadFailure extends HomeState {
  const HomeLoadFailure(this.error);

  final Object error;

  @override
  List<Object?> get props => [HomeLoadFailure, error];
}

final class HomeLoaded extends HomeState {
  HomeLoaded({required this.catalog, required this.progressSnapshot})
    : questionSummary = practiceQuestionPolicy.summarize(
        questions: catalog.questions,
        progressSnapshot: progressSnapshot,
      );

  final QuestionCatalog catalog;
  final QuestionProgressSnapshot progressSnapshot;
  final PracticeQuestionSummary questionSummary;

  List<Question> get questions => catalog.questions;

  int get totalQuestionCount => questionSummary.totalCount;

  int get correctQuestionCount => questionSummary.masteredCount;

  int get incorrectQuestionCount => questionSummary.needsReviewCount;

  int get unansweredQuestionCount => questionSummary.unansweredCount;

  Map<String, int> get pendingQuestionCountsBySection =>
      questionSummary.unansweredCountsBySection;

  HomeLoaded copyWith({QuestionProgressSnapshot? progressSnapshot}) {
    return HomeLoaded(
      catalog: catalog,
      progressSnapshot: progressSnapshot ?? this.progressSnapshot,
    );
  }

  @override
  List<Object?> get props => [HomeLoaded, catalog, progressSnapshot];
}
