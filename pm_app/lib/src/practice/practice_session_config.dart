import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';

enum PracticeMode { standard, review, pending, simulacro, singleQuestion }

@immutable
final class PracticeSessionConfig extends Equatable {
  const PracticeSessionConfig.standard({
    this.initialSection = '1A',
    this.shuffleAnswers = true,
  }) : mode = PracticeMode.standard,
       pendingBatchSize = 10,
       pendingLoadThreshold = 5,
       pendingQuestionCount = null,
       pendingQuestionCountsBySection = const {};

  const PracticeSessionConfig.review({
    this.initialSection,
    this.shuffleAnswers = true,
  }) : mode = PracticeMode.review,
       pendingBatchSize = 10,
       pendingLoadThreshold = 5,
       pendingQuestionCount = null,
       pendingQuestionCountsBySection = const {};

  factory PracticeSessionConfig.pending({
    String? initialSection,
    bool shuffleAnswers = true,
    int pendingBatchSize = 10,
    int pendingLoadThreshold = 5,
    int? pendingQuestionCount,
    Map<String, int> pendingQuestionCountsBySection = const {},
  }) {
    assert(pendingBatchSize > 0);
    assert(pendingLoadThreshold >= 0);
    if (pendingQuestionCount != null && pendingQuestionCount < 0) {
      throw ArgumentError.value(
        pendingQuestionCount,
        'pendingQuestionCount',
        'Must not be negative.',
      );
    }
    if (pendingQuestionCountsBySection.values.any((count) => count < 0)) {
      throw ArgumentError.value(
        pendingQuestionCountsBySection,
        'pendingQuestionCountsBySection',
        'Counts must not be negative.',
      );
    }
    if (pendingQuestionCount != null &&
        pendingQuestionCountsBySection.isNotEmpty &&
        pendingQuestionCount !=
            pendingQuestionCountsBySection.values.fold(
              0,
              (sum, count) => sum + count,
            )) {
      throw ArgumentError(
        'Pending question totals must match their section counts.',
      );
    }

    return PracticeSessionConfig._(
      mode: PracticeMode.pending,
      initialSection: initialSection,
      shuffleAnswers: shuffleAnswers,
      pendingBatchSize: pendingBatchSize,
      pendingLoadThreshold: pendingLoadThreshold,
      pendingQuestionCount: pendingQuestionCount,
      pendingQuestionCountsBySection: Map.unmodifiable(
        pendingQuestionCountsBySection,
      ),
    );
  }

  const PracticeSessionConfig.simulacro({this.shuffleAnswers = true})
    : mode = PracticeMode.simulacro,
      initialSection = null,
      pendingBatchSize = 10,
      pendingLoadThreshold = 5,
      pendingQuestionCount = null,
      pendingQuestionCountsBySection = const {};

  const PracticeSessionConfig.singleQuestion({this.shuffleAnswers = true})
    : mode = PracticeMode.singleQuestion,
      initialSection = null,
      pendingBatchSize = 10,
      pendingLoadThreshold = 5,
      pendingQuestionCount = null,
      pendingQuestionCountsBySection = const {};

  const PracticeSessionConfig._({
    required this.mode,
    required this.initialSection,
    required this.shuffleAnswers,
    required this.pendingBatchSize,
    required this.pendingLoadThreshold,
    required this.pendingQuestionCount,
    required this.pendingQuestionCountsBySection,
  });

  final PracticeMode mode;

  /// The initially selected section, or `null` to include every section.
  final String? initialSection;
  final bool shuffleAnswers;
  final int pendingBatchSize;
  final int pendingLoadThreshold;
  final int? pendingQuestionCount;
  final Map<String, int> pendingQuestionCountsBySection;

  @override
  List<Object?> get props => [
    PracticeSessionConfig,
    mode,
    initialSection,
    shuffleAnswers,
    pendingBatchSize,
    pendingLoadThreshold,
    pendingQuestionCount,
    pendingQuestionCountsBySection,
  ];
}
