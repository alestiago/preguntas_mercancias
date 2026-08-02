import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_persistence/pm_persistence.dart';

import 'l10n/app_localizations.dart';
import 'src/home/home_page.dart';
import 'src/questions/load_questions.dart';

void main() {
  runApp(const PreguntasMercanciasApp());
}

final class PreguntasMercanciasApp extends StatelessWidget {
  const PreguntasMercanciasApp({
    super.key,
    this.loadQuestions,
    this.questionProgressStore,
  });

  final LoadQuestions? loadQuestions;
  final QuestionProgressStore? questionProgressStore;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<QuestionProgressStore>(
      create: (_) =>
          questionProgressStore ?? DriftQuestionProgressStore.defaults(),
      dispose: (store) {
        if (questionProgressStore == null) {
          unawaited(store.close());
        }
      },
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF136F63)),
          scaffoldBackgroundColor: const Color(0xFFF6F7F9),
          useMaterial3: true,
        ),
        home: QuestionHomePage(loadQuestions: loadQuestions),
      ),
    );
  }
}
