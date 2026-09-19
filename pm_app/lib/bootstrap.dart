import 'package:flutter/widgets.dart';
import 'package:pm_persistence/pm_persistence.dart';

import 'app.dart';
import 'src/app/app_dependencies_owner.dart';

void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();

  final dependencies = AppDependencies(
    questionProgressStore: DriftQuestionProgressStore.defaults(),
    settingsStore: SharedPreferencesSettingsStore(),
  );

  runApp(
    AppDependenciesOwner(
      dependencies: dependencies,
      child: PreguntasMercanciasApp(dependencies: dependencies),
    ),
  );
}
