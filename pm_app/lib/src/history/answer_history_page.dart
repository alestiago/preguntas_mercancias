import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions/pm_questions.dart';

import 'bloc/answer_history_bloc.dart';
import 'view/answer_history_view.dart';

class AnswerHistoryPage extends StatelessWidget {
  const AnswerHistoryPage({super.key, required this.catalog});

  final QuestionCatalog catalog;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AnswerHistoryBloc(
        questionProgressStore: context.read<QuestionProgressStore>(),
        catalog: catalog,
      ),
      child: const AnswerHistoryView(),
    );
  }
}
