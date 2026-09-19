import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_persistence/pm_persistence.dart';

import '../questions/load_questions.dart';
import 'bloc/home_bloc.dart';
import 'view/question_home_view.dart';

class QuestionHomePage extends StatelessWidget {
  const QuestionHomePage({super.key, LoadQuestions? loadQuestions})
    : loadQuestions = loadQuestions ?? loadQuestionsFromBank;

  final LoadQuestions loadQuestions;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc(
        loadQuestions: loadQuestions,
        questionProgressStore: context.read<QuestionProgressStore>(),
      )..add(const HomeStarted()),
      child: QuestionHomeView(loadQuestions: loadQuestions),
    );
  }
}
