import 'package:meta/meta.dart';
import 'package:pm_questions/pm_questions.dart';

import 'practice_session_config.dart';
import 'session_question_source.dart';

const practiceLaunchFactory = PracticeLaunchFactory();

@immutable
final class PracticeLaunch {
  PracticeLaunch({required this.config, required this.source}) {
    if (config.mode != source.mode) {
      throw ArgumentError(
        'The ${config.mode.name} configuration requires a matching question '
        'source, but received ${source.mode.name}.',
      );
    }
  }

  final PracticeSessionConfig config;
  final SessionQuestionSource source;
}

final class PracticeLaunchFactory {
  const PracticeLaunchFactory();

  PracticeLaunch standard({
    required QuestionCatalog catalog,
    required bool shuffleAnswers,
    String? initialSection = '1A',
  }) {
    return _catalogLaunch(
      catalog: catalog,
      config: PracticeSessionConfig.standard(
        initialSection: initialSection,
        shuffleAnswers: shuffleAnswers,
      ),
    );
  }

  PracticeLaunch review({
    required QuestionCatalog catalog,
    required bool shuffleAnswers,
    String? initialSection,
  }) {
    return _catalogLaunch(
      catalog: catalog,
      config: PracticeSessionConfig.review(
        initialSection: initialSection,
        shuffleAnswers: shuffleAnswers,
      ),
    );
  }

  PracticeLaunch pending({
    required QuestionCatalog catalog,
    required bool shuffleAnswers,
    String? initialSection,
    int? pendingQuestionCount,
    Map<String, int> pendingQuestionCountsBySection = const {},
    int pendingBatchSize = 10,
    int pendingLoadThreshold = 5,
  }) {
    return _catalogLaunch(
      catalog: catalog,
      config: PracticeSessionConfig.pending(
        initialSection: initialSection,
        shuffleAnswers: shuffleAnswers,
        pendingBatchSize: pendingBatchSize,
        pendingLoadThreshold: pendingLoadThreshold,
        pendingQuestionCount: pendingQuestionCount,
        pendingQuestionCountsBySection: pendingQuestionCountsBySection,
      ),
    );
  }

  PracticeLaunch simulacro({
    required Iterable<Question> questions,
    required bool shuffleAnswers,
  }) {
    const mode = PracticeMode.simulacro;
    return PracticeLaunch(
      config: PracticeSessionConfig.simulacro(shuffleAnswers: shuffleAnswers),
      source: FixedSessionQuestionSource(questions: questions, mode: mode),
    );
  }

  PracticeLaunch singleQuestion({
    required Question question,
    required bool shuffleAnswers,
  }) {
    const mode = PracticeMode.singleQuestion;
    return PracticeLaunch(
      config: PracticeSessionConfig.singleQuestion(
        shuffleAnswers: shuffleAnswers,
      ),
      source: FixedSessionQuestionSource(questions: [question], mode: mode),
    );
  }

  PracticeLaunch _catalogLaunch({
    required QuestionCatalog catalog,
    required PracticeSessionConfig config,
  }) {
    return PracticeLaunch(
      config: config,
      source: CatalogSessionQuestionSource(catalog: catalog, mode: config.mode),
    );
  }
}
