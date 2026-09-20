import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_persistence/pm_persistence.dart';

import 'bloc/practice_bloc.dart';
import 'practice_launch.dart';
import 'practice_session_clock.dart';
import 'view/question_practice_view.dart';

class QuestionPracticePage extends StatefulWidget {
  const QuestionPracticePage({
    super.key,
    required this.launch,
    this.sessionClock,
  });

  final PracticeLaunch launch;
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
        launch: widget.launch,
        questionProgressStore: context.read<QuestionProgressStore>(),
      )..add(const PracticeStarted()),
      child: QuestionPracticeView(sessionClock: _sessionClock),
    );
  }
}
