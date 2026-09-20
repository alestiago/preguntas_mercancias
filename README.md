# Preguntas Mercancías

Offline Flutter application for studying the Spanish mercancías question bank.
It supports ordinary practice, pending-question practice, review retries, a
30-question simulacro, answer history, and local settings. Spanish is currently
the only application locale.

## Supported development targets

The supported app targets are Android and web, and the repository contains
runners for both. iOS and desktop runners are not checked in and are not
currently supported. The quality gate tests shared Flutter code; it does not
produce signed release artifacts.

The required toolchain is:

- Flutter 3.47.4, pinned in [`.fvmrc`](.fvmrc)
- Dart 3.12.2 or newer within that Flutter release
- FVM is recommended; an equivalent Flutter 3.47.4 installation on `PATH` also
  works

## Run the app

Install the pinned SDK and resolve the app dependencies:

```sh
fvm install
cd pm_app
fvm flutter pub get --enforce-lockfile
```

Run the web application:

```sh
fvm flutter run -d chrome
```

Or start an Android emulator or connect an Android device, then run:

```sh
fvm flutter run
```

The web runner depends on `pm_app/web/sqlite3.wasm` and
`pm_app/web/drift_worker.js`. Keep both files available when changing web
hosting or build output.

## Repository map

| Path | Responsibility |
| --- | --- |
| [`pm_app/`](pm_app/) | Flutter UI, feature state, navigation, localization, and application composition |
| [`widgetbook/`](widgetbook/) | Web component catalog for isolated `pm_app` widget states and interactions |
| [`packages/pm_questions/`](packages/pm_questions/) | Pure Dart question domain, JSON ingestion, and source parser |
| [`packages/pm_questions_bank/`](packages/pm_questions_bank/) | Canonical bank sources, compiled Flutter assets, compiler, and asset loader |
| [`packages/pm_persistence/`](packages/pm_persistence/) | Drift-backed attempts/progress and shared-preferences settings |
| [`docs/decisions/`](docs/decisions/) | Accepted behavioral and persistence decisions |
| [`docs/performance/`](docs/performance/) | Reproducible measurements supporting scaling changes |
| [`tool/verify.sh`](tool/verify.sh) | Repository-wide generation and quality gate |

The app is organized by feature under `pm_app/lib/src`. Each feature keeps its
page/view widgets beside its BLoC or Cubit. Cross-feature composition lives in
`src/app`, navigation construction in `src/navigation`, and question-loading
adapters in `src/questions`. See the [app guide](pm_app/README.md) for the
detailed feature map.

## Question-bank edition

`pm_260326` is the current bank-edition identifier. The canonical editable
inputs are under
[`packages/pm_questions_bank/assets/pm_260326/`](packages/pm_questions_bank/assets/pm_260326/).
The JSON files in `assets/pm_260326_json/` are generated, checked-in runtime
assets.

The top-level [`pm_260326/`](pm_260326/) directory is an archival copy of the
upstream source files. It is not read by the compiler or the app. Make source
corrections in the package asset directory and regenerate JSON; update the
archive separately only when deliberately replacing the archived upstream
edition.

Answers that depend on their original positions are listed in
`assets/pm_260326/non_shuffleable.txt`. See the
[question-bank guide](packages/pm_questions_bank/README.md) before changing
source or overrides.

## Generate checked-in files

Run each command from the directory shown. Generated output is committed and
must not be edited by hand.

| Output | Working directory | Command |
| --- | --- | --- |
| Flutter localization classes | `pm_app` | `fvm flutter gen-l10n` |
| Drift database code | `packages/pm_persistence` | `fvm dart run build_runner build` |
| Compiled question JSON | `packages/pm_questions_bank` | `fvm dart run tools/compile_question_assets.dart` |

The repository verification script runs all three generators and fails if they
leave tracked output different from the committed files.

## Verify changes

Run the same quality gate used by CI from the repository root:

```sh
fvm exec ./tool/verify.sh
```

If Flutter 3.47.4 is already on `PATH`, run `./tool/verify.sh` directly. The
gate resolves each package from its lockfile, checks formatting, regenerates
checked-in files, runs static analysis, and runs tests in randomized order for
the app and all three packages. The pure question package is resolved, analyzed,
and tested with Dart rather than Flutter.

For a focused test while developing:

```sh
cd pm_app
fvm flutter test test/src/practice/bloc/practice_bloc_test.dart
```

To browse the component catalog:

```sh
cd widgetbook
fvm flutter run -d chrome -t src/main.dart
```

Keep changes scoped, include tests for behavioral changes, and include any
generator output in the same reviewable change.

## Behavioral decisions

The decisions most likely to be mistaken for incidental implementation details
are recorded explicitly:

- [Review retries](docs/decisions/0001-review-retry-semantics.md)
- [“Ever correct” lifetime progress](docs/decisions/0002-ever-correct-progress.md)
- [Session completion](docs/decisions/0003-session-completion.md)
- [Persistence versioning](docs/decisions/0004-persistence-versioning.md)
- [Question-domain package boundaries](docs/decisions/0005-question-domain-boundaries.md)
