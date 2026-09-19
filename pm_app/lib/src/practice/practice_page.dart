import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_persistence/pm_persistence.dart';

import '../questions/load_questions.dart';
import 'bloc/practice_bloc.dart';
import 'practice_session_clock.dart';
import 'practice_session_config.dart';
import 'view/question_practice_view.dart';

class QuestionPracticePage extends StatefulWidget {
  const QuestionPracticePage({
    super.key,
    LoadQuestions? loadQuestions,
    this.loadMoreQuestions,
    this.session = const PracticeSessionConfig.standard(),
    this.sessionClock,
  }) : loadQuestions = loadQuestions ?? loadQuestionsFromBank;

  final LoadQuestions loadQuestions;
  final LoadMoreQuestions? loadMoreQuestions;
  final PracticeSessionConfig session;
  final PracticeSessionClock? sessionClock;

  @override
  State<QuestionPracticePage> createState() => _QuestionPracticePageState();
}

class _QuestionPracticePageState extends State<QuestionPracticePage> {
  late final PracticeSessionClock _sessionClock;

  @override
  void initState() {
    super.initState();
    _sessionClock = widget.sessionClock ?? StopwatchPracticeSessionClock();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PracticeBloc(
        loadQuestions: widget.loadQuestions,
        loadMoreQuestions: widget.loadMoreQuestions,
        questionProgressStore: context.read<QuestionProgressStore>(),
        session: widget.session,
      )..add(const PracticeStarted()),
      child: QuestionPracticeView(sessionClock: _sessionClock),
    );
  }
}
