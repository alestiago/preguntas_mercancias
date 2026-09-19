# pm_app

Flutter application for Preguntas Mercancías. This package owns presentation,
feature state, navigation, localization, and composition of the pure question,
question-bank asset, and persistence packages.

See the [repository guide](../README.md) for prerequisites, supported platforms,
question-asset ownership, generation, and the full quality gate.

## Run

From this directory:

```sh
fvm flutter pub get --enforce-lockfile
fvm flutter run -d chrome
```

Use `fvm flutter run` with an available Android device to run the Android app.

## Feature map

| Path | Responsibility |
| --- | --- |
| `lib/bootstrap.dart` | Creates production dependencies and transfers their ownership to the widget tree |
| `lib/app.dart` | Provides stores, app-wide settings state, theme, localization, and the home entry point |
| `lib/src/app/` | Dependency lifetime, shared theme tokens, and shared loading/message widgets |
| `lib/src/home/` | Catalog summary and practice entry points |
| `lib/src/practice/` | Session configuration, eligibility policy, summaries, BLoC state transitions, and practice UI |
| `lib/src/practice_summary/` | Completed simulacro/single-question summary |
| `lib/src/history/` | Ordered attempt history and one-question launch |
| `lib/src/settings/` | Answer-shuffle preference and progress reset |
| `lib/src/questions/` | Adapters for loading the bank, drawing a simulacro, and pending batches |
| `lib/src/navigation/` | Central page-route construction |
| `lib/l10n/` | Spanish ARB source and generated localization classes |

Pages create feature-specific BLoCs or Cubits. Application-scoped stores are
injected and remain owned by `AppDependenciesOwner`; feature state objects must
not close them. Tests replace those dependencies through the helpers under
`test/helpers`.

## State and event conventions

- Session kind and completion behavior come from `PracticeSessionConfig`; do
  not add another boolean mode flag.
- Lifetime question eligibility comes from `PracticeQuestionPolicy`; session
  answer status is a separate concept.
- Answer identity remains canonical even when the displayed order is shuffled;
  use `QuestionAnswerPresentation` for display mappings.
- Async loads carry a session/read generation. Completion from an older
  generation is intentionally ignored so it cannot overwrite newer state.
- Duplicate answer taps, navigation during an answer write, retries outside a
  failure state, and duplicate progress-reset requests are intentional no-ops.
  These guards protect persistence and state ordering rather than representing
  unfinished handlers.

The product behavior behind retries, progress, and completion is recorded in
[`docs/decisions`](../docs/decisions/).

## Localization

Edit `lib/l10n/app_es.arb`, then regenerate from this directory:

```sh
fvm flutter gen-l10n
```

Both `app_localizations.dart` and `app_localizations_es.dart` are generated and
checked in. User-facing feature labels and recoverable errors belong in the ARB
file rather than inline string literals.

## Test and analyze

```sh
fvm flutter analyze --no-pub
fvm flutter test --no-pub --test-randomize-ordering-seed=random
```

Use `test/helpers/pump_app.dart` for localized/theme-aware widget tests, fresh
builders from `test/fixtures`, and controlled fakes for ordering or failure
scenarios. Keep full-app tests for journeys that cross feature boundaries.

The root `fvm exec ./tool/verify.sh` command remains the required final check.
