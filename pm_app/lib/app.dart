import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_persistence/pm_persistence.dart';

import 'l10n/app_localizations.dart';
import 'src/app/app_dependencies.dart';
import 'src/home/home_page.dart';
import 'src/questions/load_questions.dart';
import 'src/settings/bloc/settings_bloc.dart';

export 'src/app/app_dependencies.dart' show AppDependencies;

final class PreguntasMercanciasApp extends StatelessWidget {
  const PreguntasMercanciasApp({
    required this.dependencies,
    super.key,
    this.loadQuestions,
  });

  final AppDependencies dependencies;
  final LoadQuestions? loadQuestions;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<QuestionProgressStore>.value(
          value: dependencies.questionProgressStore,
        ),
        RepositoryProvider<SettingsStore>.value(
          value: dependencies.settingsStore,
        ),
      ],
      child: BlocProvider<SettingsBloc>(
        lazy: false,
        create: (context) =>
            SettingsBloc(settingsStore: context.read<SettingsStore>())
              ..add(const SettingsStarted()),
        child: MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF136F63),
            ),
            scaffoldBackgroundColor: const Color(0xFFF6F7F9),
            useMaterial3: true,
          ),
          home: QuestionHomePage(loadQuestions: loadQuestions),
        ),
      ),
    );
  }
}
