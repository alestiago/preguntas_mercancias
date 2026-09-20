import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

enum PracticeMode { standard, review, pending, simulacro, singleQuestion }

/// Describes what ends a practice session.
enum PracticeCompletionPolicy {
  /// Reaching the final question restarts the current practice set.
  restartAtTerminalQuestion,

  /// Answering the final question permits completion. Earlier questions may
  /// remain unanswered and are preserved as such in the summary.
  finishAtTerminalQuestionAllowingSkipped,

  /// Completion occurs when no question remains eligible for the session.
  finishWhenEligibleQuestionsExhausted,
}

enum PracticeCompletionDestination { previousRoute, summary }

@immutable
final class PendingPracticeOptions extends Equatable {
  factory PendingPracticeOptions({
    int batchSize = 10,
    int loadThreshold = 5,
    int? initialQuestionCount,
    Map<String, int> initialQuestionCountsBySection = const {},
  }) {
    if (batchSize <= 0) {
      throw ArgumentError.value(
        batchSize,
        'batchSize',
        'Must be greater than zero.',
      );
    }
    if (loadThreshold < 0) {
      throw ArgumentError.value(
        loadThreshold,
        'loadThreshold',
        'Must not be negative.',
      );
    }
    if (initialQuestionCount != null && initialQuestionCount < 0) {
      throw ArgumentError.value(
        initialQuestionCount,
        'initialQuestionCount',
        'Must not be negative.',
      );
    }
    if (initialQuestionCountsBySection.values.any((count) => count < 0)) {
      throw ArgumentError.value(
        initialQuestionCountsBySection,
        'initialQuestionCountsBySection',
        'Counts must not be negative.',
      );
    }
    if (initialQuestionCount != null &&
        initialQuestionCountsBySection.isNotEmpty &&
        initialQuestionCount !=
            initialQuestionCountsBySection.values.fold(
              0,
              (sum, count) => sum + count,
            )) {
      throw ArgumentError(
        'Pending question totals must match their section counts.',
      );
    }

    return PendingPracticeOptions._(
      batchSize: batchSize,
      loadThreshold: loadThreshold,
      initialQuestionCount: initialQuestionCount,
      initialQuestionCountsBySection: Map.unmodifiable(
        initialQuestionCountsBySection,
      ),
    );
  }

  const PendingPracticeOptions._({
    required this.batchSize,
    required this.loadThreshold,
    required this.initialQuestionCount,
    required this.initialQuestionCountsBySection,
  });

  final int batchSize;
  final int loadThreshold;

  /// Launch-time display metadata, not the session's current eligibility.
  final int? initialQuestionCount;

  /// Launch-time display metadata, not the session's current eligibility.
  final Map<String, int> initialQuestionCountsBySection;

  @override
  List<Object?> get props => [
    PendingPracticeOptions,
    batchSize,
    loadThreshold,
    initialQuestionCount,
    initialQuestionCountsBySection,
  ];
}

@immutable
final class PracticeSessionConfig extends Equatable {
  const PracticeSessionConfig.standard({
    this.initialSection = '1A',
    this.shuffleAnswers = true,
  }) : mode = PracticeMode.standard,
       pendingOptions = null;

  const PracticeSessionConfig.review({
    this.initialSection,
    this.shuffleAnswers = true,
  }) : mode = PracticeMode.review,
       pendingOptions = null;

  factory PracticeSessionConfig.pending({
    String? initialSection,
    bool shuffleAnswers = true,
    PendingPracticeOptions? options,
  }) {
    return PracticeSessionConfig._(
      mode: PracticeMode.pending,
      initialSection: initialSection,
      shuffleAnswers: shuffleAnswers,
      pendingOptions: options ?? PendingPracticeOptions(),
    );
  }

  const PracticeSessionConfig.simulacro({this.shuffleAnswers = true})
    : mode = PracticeMode.simulacro,
      initialSection = null,
      pendingOptions = null;

  const PracticeSessionConfig.singleQuestion({this.shuffleAnswers = true})
    : mode = PracticeMode.singleQuestion,
      initialSection = null,
      pendingOptions = null;

  const PracticeSessionConfig._({
    required this.mode,
    required this.initialSection,
    required this.shuffleAnswers,
    required this.pendingOptions,
  });

  final PracticeMode mode;

  /// The initially selected section, or `null` to include every section.
  final String? initialSection;
  final bool shuffleAnswers;
  final PendingPracticeOptions? pendingOptions;

  bool get allowsSectionSelection =>
      mode != PracticeMode.simulacro && mode != PracticeMode.singleQuestion;

  bool get allowsQuestionNavigation => mode == PracticeMode.simulacro;

  bool get showsElapsedTime => mode == PracticeMode.simulacro;

  bool get showsExitAction => mode == PracticeMode.simulacro;

  bool get confirmsExitAfterAnswer => mode == PracticeMode.simulacro;

  bool get usesFilteredQuestionEligibility =>
      mode == PracticeMode.review || mode == PracticeMode.pending;

  PracticeCompletionPolicy get completionPolicy => switch (mode) {
    PracticeMode.standard => PracticeCompletionPolicy.restartAtTerminalQuestion,
    PracticeMode.simulacro || PracticeMode.singleQuestion =>
      PracticeCompletionPolicy.finishAtTerminalQuestionAllowingSkipped,
    PracticeMode.review || PracticeMode.pending =>
      PracticeCompletionPolicy.finishWhenEligibleQuestionsExhausted,
  };

  PracticeCompletionDestination? get completionDestination => switch (mode) {
    PracticeMode.standard => null,
    PracticeMode.simulacro => PracticeCompletionDestination.summary,
    PracticeMode.review ||
    PracticeMode.pending ||
    PracticeMode.singleQuestion => PracticeCompletionDestination.previousRoute,
  };

  @override
  List<Object?> get props => [
    PracticeSessionConfig,
    mode,
    initialSection,
    shuffleAnswers,
    pendingOptions,
  ];
}
