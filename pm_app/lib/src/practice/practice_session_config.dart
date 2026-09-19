import 'package:flutter/foundation.dart';

enum PracticeMode { standard, review, pending, simulacro, singleQuestion }

@immutable
final class PracticeSessionConfig {
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

  const PracticeSessionConfig.pending({
    this.initialSection,
    this.shuffleAnswers = true,
    this.pendingBatchSize = 10,
    this.pendingLoadThreshold = 5,
    this.pendingQuestionCount,
    this.pendingQuestionCountsBySection = const {},
  }) : assert(pendingBatchSize > 0),
       assert(pendingLoadThreshold >= 0),
       mode = PracticeMode.pending;

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

  final PracticeMode mode;

  /// The initially selected section, or `null` to include every section.
  final String? initialSection;
  final bool shuffleAnswers;
  final int pendingBatchSize;
  final int pendingLoadThreshold;
  final int? pendingQuestionCount;
  final Map<String, int> pendingQuestionCountsBySection;
}
