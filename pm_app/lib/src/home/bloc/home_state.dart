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
  }) : questions = List.unmodifiable(questions),
       questionSummary = practiceQuestionPolicy.summarize(
         questions: questions,
         progressSnapshot: progressSnapshot,
       );

  final List<Question> questions;
  final QuestionProgressSnapshot progressSnapshot;
  final PracticeQuestionSummary questionSummary;

  int get totalQuestionCount => questionSummary.totalCount;

  int get correctQuestionCount => questionSummary.masteredCount;

  int get incorrectQuestionCount => questionSummary.needsReviewCount;

  int get unansweredQuestionCount => questionSummary.unansweredCount;

  Map<String, int> get pendingQuestionCountsBySection =>
      questionSummary.unansweredCountsBySection;

  PracticeSessionConfig reviewSession({required bool shuffleAnswers}) {
    return PracticeSessionConfig.review(shuffleAnswers: shuffleAnswers);
  }

  PracticeSessionConfig pendingSession({required bool shuffleAnswers}) {
    return PracticeSessionConfig.pending(
      shuffleAnswers: shuffleAnswers,
      pendingQuestionCount: unansweredQuestionCount,
      pendingQuestionCountsBySection: pendingQuestionCountsBySection,
    );
  }

  LoadQuestions reviewLoadQuestions() {
    return (section) async => practiceQuestionPolicy.selectEligible(
      questions: questions,
      mode: PracticeMode.review,
      progressSnapshot: progressSnapshot,
      section: section,
    );
  }

  LoadQuestions pendingLoadQuestions({required int batchSize}) {
    return (section) async => practiceQuestionPolicy.selectEligible(
      questions: questions,
      mode: PracticeMode.pending,
      progressSnapshot: progressSnapshot,
      section: section,
      limit: batchSize,
    );
  }

  LoadMoreQuestions pendingLoadMoreQuestions({required int batchSize}) {
    return (section, loadedQuestionCodes, latestProgressSnapshot) async {
      return practiceQuestionPolicy.selectEligible(
        questions: questions,
        mode: PracticeMode.pending,
        progressSnapshot: latestProgressSnapshot,
        section: section,
        excludedQuestionCodes: loadedQuestionCodes,
        limit: batchSize,
      );
    };
  }

  HomeLoaded copyWith({QuestionProgressSnapshot? progressSnapshot}) {
    return HomeLoaded(
      questions: questions,
      progressSnapshot: progressSnapshot ?? this.progressSnapshot,
    );
  }
}
