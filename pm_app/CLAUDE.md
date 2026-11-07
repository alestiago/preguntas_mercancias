# pm_app: agent notes

See [README.md](README.md) for the feature map and the state conventions. Rules
agents most often get wrong:

- **Session modes**: behavior comes from `PracticeSessionConfig`
  (`lib/src/practice/practice_session_config.dart`). Never add boolean mode
  flags. A new mode must pick an explicit completion policy (ADR 0003).
- **Eligibility vs. session status**: lifetime eligibility is
  `PracticeQuestionPolicy`. Session answer status is a separate concept (ADR 0002).
- **Answer identity**: stored and compared options are canonical. Shuffling is
  display-only through `QuestionAnswerPresentation`.
- **Async generations**: loads carry a generation number. Results from older
  generations are dropped on purpose. Keep that guard.
- **Intentional no-ops**: duplicate taps, navigation during an answer write and
  duplicate reset requests are ignored on purpose. Don't "fix" them.
- **Ownership**: stores belong to `AppDependenciesOwner`. BLoCs and Cubits are
  consumers and must never close injected stores.
- **Strings**: edit `lib/l10n/app_es.arb`, then run `fvm flutter gen-l10n`.
  Never edit `app_localizations*.dart`. Stage the generated files before
  running `verify.sh`, which compares them against the git index.
- **Tests**: use `test/helpers/pump_app.dart`, the fakes in `test/helpers/` and
  the builders in `test/fixtures/`. Mirror `lib/` paths under `test/src/`.
- **Onboarding in app tests**: `pumpApp` defaults to an onboarded user. If you
  pass your own `FakeSettingsStore`, set `onboardingCompleted: true` unless the
  test is about onboarding. Otherwise the app opens on onboarding, not home.
- **Onboarding never blocks**: the gate sends the user home when settings fail
  to load or the flag can't be written. Don't turn it into a hard gate.
- **Widgetbook**: a widget exported from `lib/component_library.dart` needs a
  use case in `../widgetbook/src/pm_app/lib/src/...` at the mirrored path.

Check: `fvm exec ../tool/verify.sh --only pm_app` (also include `widgetbook` if
you touched exported widgets).
