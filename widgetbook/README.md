# Preguntas Mercancias Widgetbook

Interactive catalog for the reusable widgets in `pm_app`.

The use-case sources under `src/pm_app/lib/src` mirror the production feature
tree. They import the real widgets through `package:pm_app/component_library.dart`;
they do not copy widget implementations.

## Run

From this directory, resolve the locked dependencies and launch the web app:

```sh
fvm flutter pub get --enforce-lockfile
fvm flutter run -d chrome -t src/main.dart
```

Callbacks display a floating `SnackBar` naming the callback and its value.
Use the Widgetbook knobs panel to vary the inputs that affect each component.

## Verify

```sh
fvm flutter analyze --no-pub
fvm flutter test --no-pub --test-randomize-ordering-seed=random
```

The repository-wide `fvm exec ./tool/verify.sh` command also checks this app.
