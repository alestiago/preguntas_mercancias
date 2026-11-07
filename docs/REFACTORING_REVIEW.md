# Refactoring review: Preguntas Mercancías

> **Status (2026-11-06):** most items are implemented. For each item's current status, see [plans/backlog.md](../plans/backlog.md). Open work is tracked in GitHub Issues. The baseline described below is historical.

Reviewed on **2026-09-19**, against commit **`7c74c11` (`footer`)**.

The highest-value work is to make practice sessions explicit and reliable, centralize question-selection rules, and reduce the responsibilities of the large screen files. The code already has useful boundaries; an incremental refactor can build on them.

This document is a proposed backlog. It does not implement the changes. **R01 is backed by a failing existing test.** Other behavioral risks are identified through source inspection unless stated otherwise. Performance opportunities are hypotheses to measure, not measured production bottlenecks.

## Scope and baseline

The review covers application code, both local packages, test suites and helpers, question compilation, localization, dependency manifests, and checked-in platform configuration. Generated Drift and localization code is excluded from maintainability size comparisons; its generation process remains in scope. The question corpus was checked structurally, not reviewed for the correctness of its educational content.

| Area | Current shape |
| --- | --- |
| `pm_app` | Flutter app with home, practice, history, settings, and summary features; 23 handwritten Dart library files, 3,975 lines excluding localization |
| `pm_questions_bank` | 8 Dart library files, 501 lines; models, JSON validation, TXT parser, Flutter asset loader |
| `pm_persistence` | 11 handwritten Dart library files, 451 lines; storage interfaces, Drift implementation, SharedPreferences implementation |
| Question corpus | 4,475 JSON questions across 8 sections; no duplicate question codes found |
| Largest implementation files | `practice_page.dart`: 940 lines; `home_page.dart`: 601; `practice_bloc.dart`: 388; `answer_history_page.dart`: 356 |
| Test organization | Focused package/BLoC tests plus an 845-line app `widget_test.dart` |
| Repository automation | No checked-in CI workflow or root workspace manifest found |

### Checks actually run

Environment: **Flutter 3.47.4 / Dart 3.13.3**. Commands used the existing dependency resolution (`--no-pub`).

| Working directory | Command | Result |
| --- | --- | --- |
| `pm_app` | `flutter analyze --no-pub` | Exit 1: one informational `prefer_initializing_formals` diagnostic in `test/helpers/fake_settings_store.dart:7` |
| `pm_app` | `flutter test --no-pub --reporter expanded` | **40 passed, 1 failed**: review-mode looping test times out after 30 seconds |
| `packages/pm_persistence` | `flutter analyze --no-pub` | Passed |
| `packages/pm_persistence` | `flutter test --no-pub --reporter expanded` | **6 passed** |
| `packages/pm_questions_bank` | `flutter analyze --no-pub` | Passed |
| `packages/pm_questions_bank` | `flutter test --no-pub --reporter expanded` | **17 passed**, including loading all 4,475 bundled questions |

No coverage percentage, release build, browser persistence check, device interaction test, or performance benchmark was produced. Passing package analysis does not imply a shared lint policy: only the app has an `analysis_options.yaml`.

### What to preserve

- Feature-oriented organization and the existing Page/View separation in home and practice.
- `QuestionProgressStore` and `SettingsStore` interfaces, constructor injection, and provider-based composition.
- Sealed loading/failure/loaded states and exhaustive switches where appropriate.
- Drift transactions that update attempt history and aggregate progress together.
- Immutable `Question.answers`, `HomeLoaded.questions`, and progress snapshots.
- JSON schema validation and the curated `shuffleable` flag. Positional answer references must remain meaningful.
- Standard Flutter widgets, generated ARB localization, `intl`, `collection`, and `flutter_sticky_header` already doing useful work.
- Seedable randomness in sampling and shuffling, and tests that protect balancing across sections.
- Existing behavior that a question remains “correct” on home after it has ever been answered correctly, even after a later incorrect attempt.

## Architectural direction

Keep the current app and packages, and establish clearer logical boundaries first:

```text
App composition: dependencies, theme, navigation
    ├── Feature pages/views: rendering and user interactions
    ├── Feature BLoCs: screen and session transitions
    ├── Question catalog + practice policies: reusable selection and scoring
    └── Storage / asset adapters: Drift, preferences, AssetBundle
```

Views should issue actions and render prepared state. BLoCs should receive dependencies rather than create databases. Shared product rules should have one named implementation. Flutter-specific loading and SQL details should stay behind adapters.

VGV describes both layered architecture and feature-first clean architecture (FFCA). The latter adds package boundaries per feature layer. For this repository, start with the existing packages and explicit APIs; consider additional packages when there is a concrete reuse or isolation requirement. This is a project-specific judgment, not a claim that VGV mandates this exact layout. [VGV layered architecture](https://engineering.verygood.ventures/architecture/architecture/), [FFCA overview](https://engineering.verygood.ventures/architecture/ffca/overview/).

## Prioritized backlog

Priorities: **P0** fixes the demonstrated broken baseline; **P1** addresses state correctness and the highest recurring maintenance costs; **P2** consolidates reusable code and tooling; **P3** is conditional work. Effort is relative: **S** is a focused local change, **M** spans a feature and tests, **L** crosses contracts or package boundaries. These are not calendar estimates.

| ID | Priority | Effort | Refactoring effort | Main payoff |
| --- | --- | --- | --- | --- |
| R01 | P0 | M | Separate review attempts from saved answer selections | Restore repeat attempts and a passing baseline |
| R02 | P1 | M | Define BLoC concurrency and stale-result rules | Prevent old work overwriting newer sessions |
| R03 | P1 | M | Model saving and failure recovery explicitly | Make persistence outcomes visible and recoverable |
| R04 | P1 | M | Replace mode booleans with typed session configuration | Remove invalid combinations and default drift |
| R05 | P1 | M | Extract question eligibility and selection policies | One implementation of review/pending rules |
| R06 | P1 | M | Give pending batches an explicit result contract | Reliable completion and retry behavior |
| R07 | P1 | M | Centralize navigation, completion, and exit policies | Consistent entry/exit behavior |
| R08 | P1 | M | Use one session clock and elapsed-time formatter | Consistent timer and summary |
| R09 | P1 | M | Put history and settings operations behind feature state | Simpler views and explicit failures |
| R10 | P1 | M | Make initialization and observation contracts consistent | Eliminate competing reads and subscriptions |
| R11 | P2 | S–M | Consolidate dependency creation and resource ownership | Predictable lifecycle and test setup |
| R12 | P2 | M | Split large page libraries by responsibility | Discoverable, independently testable components |
| R13 | P2 | S | Share loading, error, and empty-state presentation | Remove repeated screen scaffolding |
| R14 | P2 | M | Centralize theme tokens and answer-status presentation | Consistent styling with fewer copies |
| R15 | P2 | S–M | Make state snapshots immutable and equality consistent | Reliable state comparisons |
| R16 | P2 | M | Separate answer identity from shuffled presentation | Preserve storage semantics while simplifying UI |
| R17 | P2 | M | Add a reusable catalog and validated section metadata | Reuse loaded data and remove duplicated lists |
| R18 | P2 | M–L | Separate pure domain APIs from Flutter and serialization | Reusable models and smaller dependency surfaces |
| R19 | P2 | M | Make question-asset compilation reproducible | Prevent source/output drift |
| R20 | P2 | M | Specify persistence invariants and migration workflow | Safer storage evolution |
| R21 | P2 | M | Refactor test organization and asynchronous assertions | Faster diagnosis and less harness duplication |
| R22 | P1 | M | Establish a shared quality gate across all packages | Keep the refactor verifiable |
| R23 | P2 | S | Replace template documentation with project guidance | Faster onboarding and fewer repeated decisions |
| R24 | P2 | S–M | Finish localization, semantics, and responsive layout cleanup | Easier presentation changes |
| R25 | P2 | S–M | Centralize app metadata and build configuration | Remove manual version and release drift |
| R26 | P3 | M | Bound work on large histories and long practice sessions | Scale when measurements justify it |
| R27 | P2 | S | Remove tracked build caches and standardize ignore rules | Clean diffs and reproducible checkouts |

## Detailed efforts

### R01 — Separate review attempts from saved answer selections

**Evidence:** [PracticeBloc](../pm_app/lib/src/practice/bloc/practice_bloc.dart), `_onAnswerPressed` at line 92 and `_nextFilteredState` at line 252; [PracticeLoaded](../pm_app/lib/src/practice/bloc/practice_state.dart), `selectedOption`/`answered`; [existing review test](../pm_app/test/src/practice/bloc/practice_bloc_test.dart), starting at line 503, waiting for an unanswered revisit at line 570.

The session stores one selected option per question code. When a wrong question is revisited in review mode, navigation only changes `currentIndex`; the saved selection remains. `answered` stays true, the buttons stay disabled, and `_onAnswerPressed` rejects another attempt. The existing test reproduces this mismatch and times out.

Introduce an explicit current attempt, or reopen the selection for a review question when it becomes the active retry. Keep attempt totals separate from the map used to render a question's latest result. Ordinary exam navigation must still retain prior answers.

**Done when:** the existing test passes; a single incorrect review question can be attempted repeatedly; a multi-question review loops correctly; exam back/forward navigation preserves answers; each actual attempt is persisted once. Do not “fix” this by increasing the timeout or removing the assertion.

### R02 — Define BLoC concurrency and stale-result rules

**Evidence:** [PracticeBloc](../pm_app/lib/src/practice/bloc/practice_bloc.dart), event registration at line 55, section loading at line 81, answer persistence at line 92, pending refill at line 140; [HomeBloc](../pm_app/lib/src/home/bloc/home_bloc.dart), `_loadAll` and `_onProgressRefreshed`; [SettingsBloc](../pm_app/lib/src/settings/bloc/settings_bloc.dart), toggle writes.

Async handlers capture state, await work, then emit copies of that old state. A slow section A load can finish after section B. A section change during an answer write can be overwritten by the answer handler. Pending refill begins after `isRecordingAnswer` becomes false, so navigation or another answer can occur before refill emits its captured state.

Use `bloc_concurrency` for suitable same-event policies: latest-request-wins for read requests, ordered writes where every change matters, and duplicate suppression only where losing repeated input is intentional. Coordinate related event types through a shared request/session generation or a common event bucket. Applying `sequential()` independently to every handler does **not** serialize different event types, and canceling a handler does not roll back a database write. [VGV event transformers](https://engineering.verygood.ventures/development/state_management/bloc_event_transformers/).

**Done when:** controlled `Completer` tests resolve A/B loads out of order, change sections during save, navigate during refill, and close during load without stale state or duplicate writes. Preserve newer selections when merging an appended batch.

### R03 — Model saving and failure recovery explicitly

**Evidence:** [PracticeBloc](../pm_app/lib/src/practice/bloc/practice_bloc.dart), `_onAnswerPressed`; [SettingsBloc](../pm_app/lib/src/settings/bloc/settings_bloc.dart), `_onAnswerShuffleToggled`; [settings reset](../pm_app/lib/src/settings/settings_page.dart), `_confirmResetProgress`; [app startup](../pm_app/lib/main.dart).

Practice optimistically increments counters and saves the selection. If persistence fails, the handler only clears the busy flag and calls `addError`; the question stays answered. A committed write followed by a failed `loadSnapshot()` enters the same catch block as a failed write. Blindly retrying the whole operation could record a duplicate attempt. Settings writes/reset also lack a visible failure path, and no application `BlocObserver` is configured here.

Represent save status and recoverable failures in state. Distinguish “answer not committed” from “answer committed, progress refresh failed.” Choose rollback or an explicit unsaved-answer retry for the first case, and refresh-only retry for the second. Consider an attempt identifier if idempotent retries become necessary. Add centralized error reporting with stack traces and localized UI messages through listeners. Avoid exposing raw exception strings as the user-facing explanation. [VGV error handling](https://engineering.verygood.ventures/development/error_handling/).

**Done when:** write failure, read-after-write failure, reset failure, and settings failure each have a deterministic state and recovery action; retries never double-count a committed answer.

### R04 — Replace mode booleans with typed session configuration

**Evidence:** [QuestionPracticePage](../pm_app/lib/src/practice/practice_page.dart), constructor at line 16; [PracticeBloc](../pm_app/lib/src/practice/bloc/practice_bloc.dart), constructor; [PracticeState](../pm_app/lib/src/practice/bloc/practice_state.dart); [history launch](../pm_app/lib/src/history/answer_history_page.dart), line 39.

`isReviewMode`, `isPendingMode`, and `isSimulacroMode` are propagated through pages, BLoCs, and states. Exclusivity is only asserted in the BLoC constructor. History reuses `isSimulacroMode: true` for one-question practice and leaves `shuffleAnswers` at its default, while home explicitly reads settings.

Start with a `PracticeMode` enum and an immutable session request. Use sealed configurations only where modes require different data. A single-question launch should be named for its actual purpose and receive the same persisted shuffle preference. Replace nullable section strings meaning “all sections” with a clearly documented selection type if this simplifies the API.

Illustrative API, not an implementation requirement:

```dart
enum PracticeMode { standard, review, pending, simulacro, singleQuestion }

// Session configuration owns mode, section, shuffle policy, and batch options.
// A launch coordinator resolves dependencies and current preferences once.
```

**Done when:** contradictory modes cannot be constructed, every launch path has tested defaults, and a feature can start a session without passing three mode flags and loosely related counts.

### R05 — Extract question eligibility and selection policies

**Evidence:** [home extensions](../pm_app/lib/src/home/home_page.dart), `_HomeLoadedPracticeSources` at line 519 and `_QuestionListPracticeFilters` at line 570; [home counts](../pm_app/lib/src/home/bloc/home_state.dart); [PracticeBloc](../pm_app/lib/src/practice/bloc/practice_bloc.dart), `_questionsForCurrentMode`; [PracticeLoaded](../pm_app/lib/src/practice/bloc/practice_state.dart), `remainingFilteredQuestions`.

The rules “no progress means pending” and “attempted but never correct means review” appear in multiple layers. Home widgets also build loaders, filter questions, count pending questions by section, and slice batches. A rule change therefore requires coordinating UI, state getters, and BLoC internals.

Extract pure classification and selection functions, or a small practice policy object. Define distinct concepts for lifetime question progress and current-session answer status. Have the BLoC compose catalog data with a progress snapshot, and expose prepared counts and session requests to the view. Avoid a general-purpose rules engine.

**Done when:** one implementation defines eligibility; home counts agree with session selection; unknown historical question codes remain excluded from current-bank counts; tests retain the “ever correct” behavior. This follows the separation of rendering and product rules described in [VGV layered architecture](https://engineering.verygood.ventures/architecture/architecture/).

### R06 — Give pending batches an explicit result contract

**Evidence:** [LoadMoreQuestions and refill](../pm_app/lib/src/practice/bloc/practice_bloc.dart), lines 13 and 140; [home batching](../pm_app/lib/src/home/home_page.dart), `_pendingPracticeBatchSize` and `pendingQuestionBatch`; [practice presentation counts](../pm_app/lib/src/practice/practice_page.dart), line 897.

The caller and BLoC both know the batch size of 10. Exhaustion is inferred from returned list length; it is stored in a mutable BLoC field rather than session state. Refill failures only report an error. A failed final refill can leave no loaded pending questions, making completion appear possible even though the source was never exhausted.

Return a named batch result containing questions and `hasMore` or an equivalent completion marker. Put loading, retryable failure, and exhaustion in session state. Keep batch size in one configuration. Define whether displayed totals are the launch total or the current eligible total, and update them consistently. For the bundled in-memory catalog, an offset/token is optional; a remote pagination framework is unnecessary.

**Done when:** exact-size final batches, empty batches, duplicates, transient failures, and section changes are covered; completion requires both no remaining questions and confirmed exhaustion; retry is possible without restarting the whole session.

### R07 — Centralize navigation, completion, and exit policies

**Evidence:** [home navigation](../pm_app/lib/src/home/home_page.dart), `_openPractice`; [practice navigation](../pm_app/lib/src/practice/practice_page.dart), `PopScope` at line 90 and `_finishSimulacro` at line 167; [footer decisions](../pm_app/lib/src/practice/widgets/practice_session_footer.dart); [exit button](../pm_app/lib/src/practice/widgets/exit_practice_button.dart); [summary navigation](../pm_app/lib/src/practice_summary/practice_summary_page.dart).

The footer and BLoC independently calculate terminal actions. The footer permits finishing when the last question is answered even if earlier questions were skipped, while `PracticeSummary` documentation says every question is answered. The custom exit button confirms leaving an answered exam, but `PopScope` only blocks while saving; it does not apply the same confirmation to system back. A history-launched summary's “back to home” action simply pops to history.

Have session state expose the available primary action and a completion policy. Specify whether early completion is allowed and how unanswered questions are represented. Centralize route construction and route exit confirmation; preserve the existing Navigator initially if it meets requirements. If URL-addressable screens are needed, use typed `go_router` routes and reconstructible identifiers rather than passing loaders and live objects through routes. [VGV routing](https://engineering.verygood.ventures/development/ui/navigation/), [FFCA navigation](https://engineering.verygood.ventures/architecture/ffca/navigation/).

**Done when:** toolbar exit and system back follow one rule; saving cannot accidentally lose the active operation; early finish and skipped answers are tested; summary destinations match their labels. Browser reload of an active session requires a separate persistence decision, even after adding a router.

### R08 — Use one session clock and elapsed-time formatter

**Evidence:** [app-bar timer](../pm_app/lib/src/practice/widgets/practice_page_app_bar.dart), `_SimulacroElapsedTimerState` at line 96; [practice page](../pm_app/lib/src/practice/practice_page.dart), `_startedAt` at line 77; [summary formatter](../pm_app/lib/src/practice_summary/practice_summary_page.dart), line 141.

The visible timer counts periodic callbacks. The summary independently subtracts two wall-clock timestamps. These can disagree after delayed callbacks, backgrounding, or system-clock changes. The same duration formatting logic exists in two files.

Give the session one elapsed-time source. A Dart `Stopwatch` is enough for elapsed running time; an injected clock/time source is appropriate if the product intentionally measures wall time across lifecycle transitions. Let UI ticks request the current elapsed duration instead of defining elapsed time themselves. Extract one presentation formatter.

**Done when:** live and final elapsed time agree; initialization/retry timing semantics are documented; background and resume behavior is intentional; 59 seconds, 60 seconds, and over an hour are covered with deterministic time. No timer package is necessary for this extraction.

### R09 — Put history and settings operations behind feature state

**Evidence:** [AnswerHistoryPage](../pm_app/lib/src/history/answer_history_page.dart), `_AnswerHistoryBody.build` and `_historySectionsFor`; [SettingsPage](../pm_app/lib/src/settings/settings_page.dart), reset callback.

History creates `watchAnswerHistory()` inside `build`, builds a catalog index, joins records to questions, and groups dates in the view library. A rebuild of that widget creates a new stream instance. Settings directly clears storage and controls operation feedback in the widget.

Add a small history Cubit/BLoC that owns one subscription and exposes grouped history state. Move question lookup and date grouping into named transformations; keep locale-specific formatting in presentation. Extend settings state with reset progress and failures, or use a focused reset controller if its lifetime differs. Continue using Drift's watch API and the existing sticky-header package.

**Done when:** view rebuilds do not recreate subscriptions; history loading/error/empty/loaded states can be rendered independently; missing questions remain displayable; reset has busy/success/failure states and cannot be submitted repeatedly while active.

### R10 — Make initialization and observation contracts consistent

**Evidence:** [HomeBloc](../pm_app/lib/src/home/bloc/home_bloc.dart), subscription plus `_loadAll`/refresh; [SettingsBloc](../pm_app/lib/src/settings/bloc/settings_bloc.dart), subscription plus `_onStarted`; [SharedPreferencesSettingsStore](../packages/pm_persistence/lib/src/stores/shared_preferences_settings_store.dart), line 19; [fake progress store](../pm_app/test/helpers/fake_question_progress_store.dart).

Settings is initialized through both an initial stream value and a separate load. Home similarly mixes a watched snapshot, explicit loads, and route-return refreshes. The fake's `watchSnapshot()` emits only future updates, unlike Drift's initial query result. These differences make ordering assumptions hard to see and test. The preferences adapter's initial async read followed by a broadcast subscription also needs an explicit contract for writes during subscription setup.

The adapter also ignores the boolean result from `SharedPreferences.setBool` and broadcasts the requested value afterward. Treat an unsuccessful write as a failure rather than an observed successful preference change.

Specify whether each watch API emits the current value, how errors are surfaced, and whether updates from other adapter instances are observable. Prefer one initialization path per feature. Remove manual route-return refresh only after all supported writes are reliably observed. Retain explicit subscriptions with correct cleanup, or use BLoC's stream helpers where they simplify ownership; avoid inventing a generic reactive base class.

**Done when:** initial emission, writes during startup, late subscribers, stream errors, and disposal behave consistently in fakes and real adapters. Consider newer SharedPreferences APIs only with a tested migration of the existing preference. [SharedPreferences documentation](https://pub.dev/packages/shared_preferences).

### R11 — Consolidate dependency creation and resource ownership

**Evidence:** [PreguntasMercanciasApp](../pm_app/lib/main.dart), providers; [PracticeBloc](../pm_app/lib/src/practice/bloc/practice_bloc.dart), optional store and `_ownsQuestionProgressStore`; [QuestionHomePage](../pm_app/lib/src/home/home_page.dart), provider fallback.

App startup already owns default stores, but `PracticeBloc` can also create its own production database. Depending on the entry path, dependencies come from parameters, providers, or internal defaults. Ownership flags spread lifecycle knowledge into business logic.

Make production dependency creation a single composition-root responsibility and require BLoC dependencies. Keep test injection through explicit page/module inputs or a reusable test harness. If bootstrap grows, separate `main`, bootstrap, and the app widget. There is no need to add a service locator: existing `RepositoryProvider`/`BlocProvider` already fit this code.

**Done when:** all launch paths share the intended store; BLoCs never instantiate Drift; injected dependencies are not unexpectedly closed; app-owned resources close once. Handle asynchronous close failures deliberately rather than relying on an unobserved `unawaited` future.

### R12 — Split large page libraries by responsibility

**Evidence:** [practice page](../pm_app/lib/src/practice/practice_page.dart), 940 lines; [home page](../pm_app/lib/src/home/home_page.dart), 601; [history page](../pm_app/lib/src/history/answer_history_page.dart), 356.

These files already use small widget classes, which is good. The remaining problem is that navigation, business extensions, styles, and many independently meaningful widgets share the same library. Private views also make isolated tests less convenient.

Keep page files focused on injection. Move views into `view/` and meaningful components into `widgets/`: question panel/answer option, feedback, section selector, home progress summary, history list/date header. Move business extensions through R05/R09 rather than merely relocating them. Export only supported feature entry points; BLoC `part` files need no extra barrel. [VGV widgets](https://engineering.verygood.ventures/development/ui/widgets/), [barrel files](https://engineering.verygood.ventures/architecture/barrel_files/).

**Done when:** a developer can locate and test the answer panel or history view without navigating unrelated routing and policy code. Use test-visible view constructors where helpful. Keep tightly coupled tiny private helpers together; a file-per-widget target would create unnecessary navigation overhead.

### R13 — Share loading, error, and empty-state presentation

**Evidence:** [home loading/error widgets](../pm_app/lib/src/home/home_page.dart), line 462; [practice loading/error widgets](../pm_app/lib/src/practice/practice_page.dart), line 813; [history state widgets](../pm_app/lib/src/history/answer_history_page.dart).

Three identical loading indicators and near-identical error layouts are maintained separately. History errors show only the raw exception, while the other pages add a localized heading and retry.

Extract a small app-local loading indicator and message panel with message, icon, and optional action. Pass localized strings and callbacks from the feature. Keep failure classification outside shared UI. An entire `AsyncState<T>` framework or a separate UI package is unnecessary for these components.

**Done when:** changing shared spacing or retry presentation happens once; every feature retains the right message/action; shared widgets have no storage or BLoC dependency. Resolve R03's error semantics before standardizing the failure display.

### R14 — Centralize theme tokens and answer-status presentation

**Evidence:** [app theme](../pm_app/lib/main.dart); [practice styles](../pm_app/lib/src/practice/practice_page.dart), `_AnswerOptionStyle` and `_AnswerFeedbackStyle`; [progress divider](../pm_app/lib/src/practice/widgets/practice_progress_divider.dart); [drawer styles](../pm_app/lib/src/practice/widgets/question_navigation_drawer.dart); [summary](../pm_app/lib/src/practice_summary/practice_summary_page.dart).

Success/error colors and container variants recur across home, feedback, history, drawer, and summary. Width 860 and related spacing also recur. Separate status enums and mapping logic describe the same per-session pending/correct/incorrect result. The progress divider currently renders both correct and incorrect completed segments green; that may deliberately mean “answered,” so it must not be silently recolored during extraction.

Create an app theme module with typography, layout constants, and semantic result colors using `ColorScheme` plus a `ThemeExtension` where Material has no matching role. Reuse an answer-status model while keeping each component's visual mapping explicit. Configure standard components through `ThemeData` where possible. [VGV theming](https://engineering.verygood.ventures/development/ui/theming/).

**Done when:** semantic colors and shared layout tokens are defined once; existing divider semantics are preserved or changed in a separately specified behavior change; representative UI states have visual verification. Do not introduce a dependency merely to name a handful of colors.

### R15 — Make state snapshots immutable and equality consistent

**Evidence:** [PracticeLoaded](../pm_app/lib/src/practice/bloc/practice_state.dart), line 48; [PracticeSummary](../packages/pm_questions_bank/lib/src/models/practice_summary.dart); [HomeState](../pm_app/lib/src/home/bloc/home_state.dart); [progress model equality](../packages/pm_persistence/lib/src/models/question_progress.dart).

`PracticeLoaded` and `PracticeSummary` accept mutable lists/maps without defensive copying, unlike `Question` and `QuestionProgressSnapshot`. BLoC states have identity equality, while domain models maintain manual equality/hash implementations. Separate supplied counts can disagree with selected answers; review attempts also mean that attempt totals cannot always be derived from the latest-selection map.

Make public snapshots defensively immutable. Define which counts represent attempts, distinct answered questions, and latest results. Use one value-equality approach for data-bearing states. Existing `collection` equality is sufficient; evaluate Equatable or code generation only if it materially reduces recurring maintenance. Preserve distinct operation transitions when equal payloads still need different UI effects.

**Done when:** caller mutation cannot change an emitted state or summary; equality matches meaningful data; derived counts are consistent; review totals retain all attempts. Keep sealed states for mutually exclusive phases and introduce an operation status within loaded state where existing data must remain visible. [VGV state handling](https://engineering.verygood.ventures/development/state_management/bloc_state_handling/).

### R16 — Separate answer identity from shuffled presentation

**Evidence:** [PracticeBloc shuffling](../pm_app/lib/src/practice/bloc/practice_bloc.dart), `_questionWithShuffledAnswers`; [practice display mapping](../pm_app/lib/src/practice/practice_page.dart), `_QuestionDisplayOptions` at line 931; [history lookup](../pm_app/lib/src/history/answer_history_page.dart), `_QuestionAnswerTextLookup`; [Question](../packages/pm_questions_bank/lib/src/models/question.dart), `answerFor`.

Shuffling reconstructs a whole `Question`, requiring every future model field to be copied manually. UI labels use display positions, while persisted answers correctly use canonical option identity. Different widgets implement their own lookup/fallback rules.

Extract a small immutable answer presentation/order model or a named question transformation. Keep canonical option IDs unchanged. Reuse `List.shuffle(Random)` and a single lookup API rather than implementing another shuffle or lookup loop. Preserve the non-shuffleable rule and explicitly document the existing additional rule that forces the correct answer away from its original position; replacing it with plain shuffle would change behavior and distribution.

**Done when:** seeded tests preserve all answer identities and texts; displayed labels match feedback; history remains correct after shuffling; positional questions never move; unsupported options fail or return a documented nullable result consistently.

### R17 — Add a reusable catalog and validated section metadata

**Evidence:** [loadQuestionsFromBank](../pm_app/lib/src/questions/load_questions.dart); [QuestionBankLoader](../packages/pm_questions_bank/lib/src/loaders/question_bank_loader.dart), sections/path map and `loadSection`; [home state getters](../pm_app/lib/src/home/bloc/home_state.dart); [simulacro sampling](../pm_app/lib/src/questions/draw_simulacro_questions.dart); [compiler section list](../packages/pm_questions_bank/tools/compile_question_assets.dart), line 8.

The loader recreates decoded/validated models on each load; a new loader is constructed by the default callback. Flutter's string caching does not cache these domain objects. Home/history also recreate indices. Sections are independently listed in the loader, asset-path map, and compiler, and sampling derives supported sections from the Flutter loader.

Introduce a small immutable question catalog with ordered questions, code lookup, and section lookup. Cache successful loads for the bundled bank and coalesce concurrent requests; failures must remain retryable. Put section metadata in a pure definition shared by loading, sampling, and compilation. Validate section/file agreement and duplicate codes at ingestion. Keep deterministic ordering.

**Done when:** repeated selection reuses decoded data; failed loads can be retried; a new section has one metadata source; all 4,475 questions still load; sampling distribution tests pass. Profile before adding isolates or a database for the read-only catalog.

### R18 — Separate pure domain APIs from Flutter and serialization

**Evidence:** [question-bank README](../packages/pm_questions_bank/README.md) calls it Dart-only; [pubspec](../packages/pm_questions_bank/pubspec.yaml) and [loader](../packages/pm_questions_bank/lib/src/loaders/question_bank_loader.dart) depend on Flutter; [primary barrel](../packages/pm_questions_bank/lib/pm_questions_bank.dart) exports models, loader, and parser together; [persistence barrel](../packages/pm_persistence/lib/pm_persistence.dart) exposes the database; [summary model](../packages/pm_questions_bank/lib/src/models/practice_summary.dart) belongs to practice results.

Start with accurate documentation and narrow entry points for pure models/parser versus Flutter asset loading. Move `PracticeSummary` to the practice/domain owner. If non-Flutter reuse is needed, split the pure domain from asset and persistence adapters at package level, not just by selective imports. BLoCs can use `package:meta` for annotations instead of importing Flutter foundation once their dependency graph is pure.

Keep JSON parsing/validation at the ingestion boundary and make direct model-construction invariants explicit. `Question.fromJson` validates four unique options, but the public `Question` factory only freezes the list. Malformed direct instances can fail later in `answerFor` or positional rendering. Avoid duplicating elaborate schema validation inside every layer. [VGV domain layer](https://engineering.verygood.ventures/architecture/ffca/domain/), [data layer](https://engineering.verygood.ventures/architecture/ffca/data/).

**Done when:** consumers have a documented API boundary; pure reuse, if undertaken, compiles/tests with Dart alone; malformed input is rejected at a defined boundary; domain imports do not expose Flutter services or generated Drift row types.

### R19 — Make question-asset compilation reproducible

**Evidence:** [compiler](../packages/pm_questions_bank/tools/compile_question_assets.dart); [TXT parser](../packages/pm_questions_bank/lib/src/parsers/question_txt_parser.dart); source directories [root corpus](../pm_260326/) and [packaged corpus](../packages/pm_questions_bank/assets/pm_260326/); [generated JSON](../packages/pm_questions_bank/assets/pm_260326_json/).

The eight root TXT files and their packaged copies are currently byte-identical. There is no documented canonical owner. Compilation relies on the working directory, writes each output before validating later sections, treats a missing non-shuffleable list as empty, and only warns about unmatched override codes. The parser overwrites repeated field labels and errors lack source line numbers.

Choose one canonical TXT location; document or remove the duplicate only after confirming its provenance purpose. Add explicit input/output arguments or a root command. Validate all input and override references before writing outputs; stage output so a failed run does not partially update the corpus. Add a check mode that regenerates to a temporary directory and compares output. Improve malformed-record diagnostics without replacing the domain-specific parser with a generic parsing framework.

**Done when:** regeneration is deterministic; CI catches stale JSON and override mistakes; missing required override metadata cannot silently make every answer shuffleable; invalid/repeated fields and section mismatches fail with file/record context. Document TXT and JSON ownership so contributors know which files to edit.

### R20 — Specify persistence invariants and migration workflow

**Evidence:** [database schema](../packages/pm_persistence/lib/src/database/pm_persistence_database.dart), schema version 1; [Drift store](../packages/pm_persistence/lib/src/stores/drift_question_progress_store.dart); [store tests](../packages/pm_persistence/test/src/stores/drift_question_progress_store_test.dart); [web runtime assets](../pm_app/web/).

Keep the existing transaction and separate attempt/aggregate tables. They serve different queries. Document that attempts equal correct plus incorrect attempts, what first/last timestamps mean, and how a changed question-bank edition affects progress keyed only by code. History renders answer text from the current bank, so edited questions can change the apparent text of an old attempt.

Before changing the schema, adopt Drift's schema snapshot and migration-testing workflow. Add targeted coverage for clear, watch updates, equal-timestamp ordering, transaction failure, and close ownership. Decide whether bank-version identity or historical answer snapshots are necessary before adding columns. Keep generated SQL/mapping code generated and document how the WASM and worker files are refreshed with compatible dependencies. [Drift migrations](https://drift.simonbinder.eu/migrations/).

**Done when:** storage semantics are documented and tested; schema changes preserve real old data through tested migrations; production history ordering and fake ordering agree; web persistence is smoke-tested on the supported hosting setup. A web worker replacement is not justified solely by its generated file size.

### R21 — Refactor test organization and asynchronous assertions

**Evidence:** [app widget tests](../pm_app/test/widget_test.dart), 845 lines; [practice BLoC tests](../pm_app/test/src/practice/bloc/practice_bloc_test.dart), repeated `stream.firstWhere` setup; [fake progress store](../pm_app/test/helpers/fake_question_progress_store.dart), duplicated aggregation logic and differing watch behavior.

Split widget scenarios into home, practice, history, settings, and summary suites, retaining a small set of full-app journeys. Provide a `pumpApp` harness for localization/theme/providers. Use fresh fixture builders and explicit seeded randomness when order matters. Use `bloc_test` for ordinary emission assertions and private controlled fakes for races and failures. Retain `Completer` where exact ordering is the subject of the test. [bloc_test](https://pub.dev/packages/bloc_test).

Specify shared adapter contract tests where fakes deliberately model real storage. Do not turn a fake into a second production persistence implementation. Prefer type/semantic finders for extracted widgets, while retaining keys that distinguish repeated answers or navigation targets. Add visual goldens only for meaningful UI states; Alchemist can supply the harness instead of maintaining a custom renderer. [VGV testing practices](https://engineering.verygood.ventures/development/testing/testing_best_practices/), [golden testing](https://engineering.verygood.ventures/development/testing/testing_golden_file/).

**Done when:** a missing transition fails close to its cause; tests assert outcomes and persistence calls, not just that a widget builds; existing journeys survive extraction; random test ordering does not expose shared mutable fixtures. Required new coverage follows the risks in R01–R10, not a line-count target.

### R22 — Establish a shared quality gate across all packages

**Evidence:** [app analysis options](../pm_app/analysis_options.yaml); all three `pubspec.yaml` files and lockfiles; absence of root workspace/CI configuration.

Resolve R01 and the current lint diagnostic first. Add one root verification entry point that runs formatting checks, analysis, and tests across the app and both packages. Adopt a consistent lint baseline; `very_good_analysis` is a suitable existing rule set. Introduce it in a focused change so new diagnostics are distinguishable from architectural edits. Both local packages need an explicit configuration. [VGV code style](https://engineering.verygood.ventures/development/code_style/).

Reuse Very Good Workflows for applicable CI steps, add generated-asset/code checks, and pin the Flutter version used by local development and CI. Consider a Dart pub workspace for one dependency resolution across packages. At three packages, a short root script is sufficient; add Melos when filtering/orchestration earns its configuration cost. [VGV CI/CD](https://engineering.verygood.ventures/development/ci_cd/), [workspace/tooling guidance](https://engineering.verygood.ventures/architecture/ffca/project_structure/).

**Done when:** a documented command checks every package from a clean checkout; CI runs it on PRs; generator drift is detected; generated files are handled explicitly. Measure coverage first and increase meaningful coverage as code is refactored. VGV advocates 100% coverage; this repository's current percentage is unknown. [VGV testing overview](https://engineering.verygood.ventures/development/testing/testing_overview/).

### R23 — Replace template documentation with project guidance

**Evidence:** [root README](../README.md), one heading; [app README](../pm_app/README.md), template content; [question-bank README](../packages/pm_questions_bank/README.md), inaccurate Dart-only claim; persistence has no README.

Document how to run the app, supported platforms, SDK requirements, package responsibilities, verification commands, and the three generation paths: localization, Drift, and question assets. Explain the bank edition, non-shuffleable overrides, and whether root source copies are archival. Add small architectural decision records for review retry semantics, “ever correct” progress, session completion, and persistence versioning.

Public storage interfaces need contracts for initial stream emission, ordering, exceptions, and ownership. Explain intentional early returns and no-op behavior where a maintainer might mistake them for unfinished work. Remove obsolete Flutter template comments from manifests when their project-specific replacement exists. [VGV documentation](https://engineering.verygood.ventures/development/documentation/documentation/), [code documentation](https://engineering.verygood.ventures/development/documentation/code_documentation/).

**Done when:** a new contributor can run, test, regenerate, and locate a feature without asking the original author. Keep PRs focused and describe behavioral changes explicitly, following [VGV code review guidance](https://engineering.verygood.ventures/general-practices/code_review/).

### R24 — Finish localization, semantics, and responsive layout cleanup

**Evidence:** [app-bar localization](../pm_app/lib/src/practice/widgets/practice_page_app_bar.dart), literal `Por Repasar` at line 179; [Spanish ARB](../pm_app/lib/l10n/app_es.arb); [history formatting](../pm_app/lib/src/history/answer_history_page.dart); [practice answer layout](../pm_app/lib/src/practice/practice_page.dart), absolute left alignment and unflexed feedback title; [question header](../pm_app/lib/src/practice/widgets/practice_question_header.dart).

Use the existing localization generation for the review title and new failures. Keep locale formatting in one presentation helper; prefer locale-aware date/time formats where product requirements permit, and define local/UTC conversion before grouping dates. Use named insets and directional alignment when the position follows text direction. Spanish is the sole current locale, so full RTL support is conditional; the inexpensive directional choices can be made during touched-widget cleanup. [VGV localization](https://engineering.verygood.ventures/development/internationalization/localization/), [directionality](https://engineering.verygood.ventures/development/internationalization/text_directionality/).

Inspect question headers, feedback rows, score pills, and footer actions with narrow widths and large text. Add accessible status/selection labels so colored progress and answer feedback remain understandable without color. Reuse Flutter's semantics and accessibility testing support instead of a bespoke accessibility layer.

**Done when:** no hardcoded feature label bypasses ARB; long content remains readable; important controls and status are announced meaningfully; relevant viewport/text-scale cases are verified. Treat possible overflow as a test target, not an already reproduced defect. [VGV layouts](https://engineering.verygood.ventures/development/ui/layouts/).

### R25 — Centralize app metadata and build configuration

**Evidence:** [settings version constant](../pm_app/lib/src/settings/settings_page.dart), line 8; [app manifest](../pm_app/pubspec.yaml), version `1.0.0+1`; [web manifest](../pm_app/web/manifest.json), template name/description/colors; [Android build configuration](../pm_app/android/app/build.gradle.kts), placeholder application ID and debug signing for release.

Read built application metadata through `package_info_plus` behind an injected app-info value, or use one generated build metadata source if already supplied by the release process. Avoid manually copying the pubspec version into UI. Test with injected metadata and verify the selected plugin's platform/toolchain requirements when implementing. [package_info_plus](https://pub.dev/packages/package_info_plus).

Replace template branding and establish the real Android identifier/signing configuration before distribution. Changing an already published application ID changes identity, so verify publication status before that edit. This release setup is adjacent maintenance work, not a prerequisite for every refactor. Document compatible web database assets and remove unused dependencies such as `cupertino_icons` only after confirming there are no consumers.

**Done when:** settings reports the built version, web metadata reflects the app, and intended release builds use an explicit supported configuration. Existing Drift and preferences storage do not justify adding authentication, encryption, or a remote backend to this offline app. Apply security work to actual requirements and observed configuration. [VGV mobile security](https://engineering.verygood.ventures/general-practices/security_in_mobile_apps/).

### R26 — Bound work on large histories and long practice sessions

**Evidence:** [Drift history query](../packages/pm_persistence/lib/src/stores/drift_question_progress_store.dart), `_answerHistorySelect`; [history grouping](../pm_app/lib/src/history/answer_history_page.dart); [filtered navigation](../pm_app/lib/src/practice/bloc/practice_bloc.dart), `_nextFilteredState`; [home getters](../pm_app/lib/src/home/bloc/home_state.dart); [question drawer](../pm_app/lib/src/practice/widgets/question_navigation_drawer.dart).

History loads every attempt and regroups them on updates. Home counts repeatedly reconstruct code sets. Filtered navigation performs repeated `indexOf` searches, which can become quadratic. The drawer eagerly builds every tile with a `GlobalKey`; it is currently limited to simulacro mode, typically only 30 questions, so this is low priority.

First measure representative large datasets. Reuse catalog indices and prepared counts. If history grows enough to matter, add bounded database queries and pagination with stable timestamp/ID ordering. If the drawer expands beyond small exams, use an existing indexed-scroll solution or a measured standard-list approach; preserve current-tile scrolling rather than blindly replacing the eager list.

**Done when:** any optimization records before/after measurements, preserves ordering/selection, and introduces less complexity than it removes. Do not replace readable bounded loops merely because a collection helper exists.

### R27 — Remove tracked build caches and standardize ignore rules

**Evidence:** `git ls-files '*/build/*' '*/.dart_tool/*'` lists 25 generated cache/build files inside `packages/pm_questions_bank`, including package resolution files, compiled test snapshots, and copied unit-test assets. The [root ignore file](../.gitignore) only excludes `.DS_Store`, while [persistence's ignore file](../packages/pm_persistence/.gitignore) excludes Dart tooling and build directories. The question-bank package has no equivalent ignore file.

The baseline test run modified a tracked `.dill` cache; that incidental modification was restored after verification. This is direct evidence that normal development produces unrelated source-control changes.

Add consistent ignore rules and remove disposable build/tool caches from Git's index in a dedicated cleanup PR, keeping developers' local files available. Adding ignore patterns alone does not untrack files already committed. Keep deliberate generated source and assets, including Drift `.g.dart`, localization output under the chosen policy, and canonical compiled question JSON, separate from disposable caches. Preserve lockfiles until the workspace-resolution policy is intentionally changed.

**Done when:** a clean checkout resolves its own package paths, a test run leaves no tracked cache changes, and asset/code generation still produces all required distributable files. This is a focused repository cleanup, not a reason to rewrite Git history.

## Reuse decisions: what should do the work

| Need | Preferred starting point | Adoption boundary |
| --- | --- | --- |
| State management and DI | Existing `bloc`, `flutter_bloc`, providers | Retain; simplify contracts and ownership |
| Event scheduling | `bloc_concurrency` | Introduce for R02; coordinate across event types explicitly |
| BLoC test scaffolding | `bloc_test`; focused controlled fakes | Introduce gradually in R21 |
| Static analysis / CI | `very_good_analysis`, Very Good Workflows | Adopt a verified common baseline; do not hide new diagnostics |
| Theming, dialogs, layout, semantics | Flutter SDK | Extract app-local components and semantic tokens |
| SQL transactions and reactive queries | Existing Drift | Retain; add migration and contract coverage |
| Preference storage | Existing SharedPreferences adapter | Tighten write/stream behavior; migrate APIs deliberately |
| Dates, localization, collection helpers | Existing `intl`, ARB generation, `collection` | Reuse instead of new formatting or collection libraries |
| Elapsed time | Dart `Stopwatch` or injected time source | No dependency required for a single timer |
| Build version | `package_info_plus` or generated build metadata | Avoid a handwritten copy of the version |
| Routing | Current Navigator; typed `go_router` for URL requirements | Centralize launch policy before migrating the router |
| Golden harness | Alchemist | Add when protecting the shared UI extraction |
| Equality/serialization generation | Existing equality/schema tools first | Evaluate additional generators only for demonstrated boilerplate |
| Question selection and TXT format | Small project-owned policies/parser | These are domain-specific; do not force an unrelated framework |
| Workspace orchestration | Dart workspace plus a short root command | Melos if command/filtering complexity grows |

Package choices above are recommendations, not dependency upgrades. Check the then-current compatibility constraints when implementing. Do not regenerate the existing app over a Very Good CLI template. A generated scratch project can serve as a reference for tooling conventions.

## Suggested implementation sequence

Each row is a stage containing small PRs, not one large change.

| Stage | Work | Exit condition |
| --- | --- | --- |
| 1. Restore confidence | R01; current lint; R27; minimum R22 verification command/CI | All existing suites and analysis pass; test runs leave clean tracked files |
| 2. Specify session behavior | R04; focused R05; regression tests for R02/R03/R06/R07 | Modes, retries, counts, completion, and failure semantics are explicit |
| 3. Stabilize async behavior | R02, R03, R06, R10; R11 as needed | Slow/failing operations cannot overwrite or lose current state |
| 4. Simplify feature ownership | R07, R08, R09, R12, R15, R16 | Views render state; session rules and resource ownership have clear homes |
| 5. Consolidate shared presentation | R13, R14, R24; relevant R21 splits/goldens | Shared UI is reusable and verified across meaningful states |
| 6. Harden data/tooling boundaries | R17, R19, R20; finish R22/R23/R25 | Reproducible assets/build metadata and documented persistence evolution |
| 7. Follow demonstrated demand | R18 package split; R26 scaling; router/workspace expansions | Each expansion has a concrete reuse, navigation, or measured performance need |

R21 test cleanup and R23 documentation should accompany the relevant stages. Avoid mixing broad formatting, file moves, changed business rules, and database migrations into the same PR. Move code mechanically first where possible, then change behavior with focused assertions.

### Behavioral decisions to record before implementation

These do not block this review; they scope the behavior-changing PRs:

- Does review count every attempt or distinct questions in its score? Existing tests expect attempt totals.
- Can an exam finish with skipped questions? If yes, represent unanswered separately from incorrect and update the summary contract.
- Does elapsed time include loading, background time, and retries?
- Does history open a practice attempt, a read-only review, or a one-question exam? It currently records another attempt through practice.
- Are pending counts fixed at session launch or continuously recalculated?
- Must active sessions survive browser refresh or process restart?
- Should progress survive a bank edition that reuses codes with changed content?

## VGV guide coverage and applicability

The guide's 32 indexed documentation pages were consulted via its [published documentation index](https://engineering.verygood.ventures/llms.txt) and Markdown pages. The mapping below makes the basis of this review explicit. It covers the site's documentation sections; it is not an audit of every external article, linked repository, or third-party service.

| Guide section | Application here |
| --- | --- |
| [Our Philosophy](https://engineering.verygood.ventures/general-practices/philosophy/) | Prefer readable, testable boundaries and incremental improvements |
| [Conventions](https://engineering.verygood.ventures/general-practices/conventions/) | R22/R23: document project conventions and release/change practices |
| [Code Reviews](https://engineering.verygood.ventures/general-practices/code_review/) | Small, reviewable PRs with explicit behavior and validation |
| [Security in Mobile Apps](https://engineering.verygood.ventures/general-practices/security_in_mobile_apps/) | R19/R25: input validation and concrete release configuration; wider controls depend on actual features |
| [Credits](https://engineering.verygood.ventures/general-practices/credits/) | Attribution for the guide; no app refactor implied |
| [Layered Architecture](https://engineering.verygood.ventures/architecture/architecture/) | R05/R09/R11: separate policy, state, views, and adapters |
| [Barrel Files](https://engineering.verygood.ventures/architecture/barrel_files/) | R12/R18: deliberate public entry points |
| [FFCA Overview](https://engineering.verygood.ventures/architecture/ffca/overview/) | Optional package evolution, not a wholesale migration requirement |
| [FFCA Domain Layer](https://engineering.verygood.ventures/architecture/ffca/domain/) | R04/R05/R18: pure models, policies, and contracts |
| [FFCA Data Layer](https://engineering.verygood.ventures/architecture/ffca/data/) | R18/R20: keep adapters and mapping out of consumers |
| [FFCA Presentation Layer](https://engineering.verygood.ventures/architecture/ffca/presentation/) | R09/R11/R12: entry points and explicit feature dependencies |
| [FFCA Navigation](https://engineering.verygood.ventures/architecture/ffca/navigation/) | R07: navigation belongs to app composition; callbacks are sufficient initially |
| [FFCA Project Structure](https://engineering.verygood.ventures/architecture/ffca/project_structure/) | R18/R22: dependency boundaries and workspace tooling |
| [FFCA FAQ](https://engineering.verygood.ventures/architecture/ffca/faq/) | Avoid needless pass-through command/query classes; auth/API examples have no current counterpart |
| [CI/CD](https://engineering.verygood.ventures/development/ci_cd/) | R22: reuse workflows and verify every package |
| [Code Style](https://engineering.verygood.ventures/development/code_style/) | R12/R22/R24: widgets, named parameters/insets, consistent linting |
| [Code Documentation](https://engineering.verygood.ventures/development/documentation/code_documentation/) | R23: explain intentional no-ops and contracts |
| [Documentation](https://engineering.verygood.ventures/development/documentation/documentation/) | R23: project/package READMEs, commands, and decisions |
| [Error Handling](https://engineering.verygood.ventures/development/error_handling/) | R03/R09: descriptive failures and documented throwing APIs |
| [Localization](https://engineering.verygood.ventures/development/internationalization/localization/) | R24: use the existing ARB workflow and localize failures |
| [Text Directionality](https://engineering.verygood.ventures/development/internationalization/text_directionality/) | R24: directional UI where appropriate; additional locale support remains conditional |
| [Bloc Event Transformers](https://engineering.verygood.ventures/development/state_management/bloc_event_transformers/) | R02: deliberate scheduling, including cross-event coordination |
| [State Handling](https://engineering.verygood.ventures/development/state_management/bloc_state_handling/) | R03/R04/R15: state shape follows data-retention needs |
| [Testing Best Practices](https://engineering.verygood.ventures/development/testing/testing_best_practices/) | R21: independent fixtures and maintainable assertions |
| [Golden File Testing](https://engineering.verygood.ventures/development/testing/testing_golden_file/) | R14/R21/R24: established harness for visual regressions |
| [Testing Overview](https://engineering.verygood.ventures/development/testing/testing_overview/) | R21/R22: mirrored structure and behavioral coverage |
| [Layouts](https://engineering.verygood.ventures/development/ui/layouts/) | R24/R26: constraints, scaling, and appropriate scrolling |
| [Routing Overview](https://engineering.verygood.ventures/development/ui/navigation/) | R07: coherent route hierarchy if URL routing is introduced |
| [Theming](https://engineering.verygood.ventures/development/ui/theming/) | R14: centralized styles and component themes |
| [Widgets](https://engineering.verygood.ventures/development/ui/widgets/) | R12/R13: reusable widgets and Page/View separation |
| [Services](https://engineering.verygood.ventures/resources/services/) | External integrations are options, not requirements for this local app |
| [Airplane Entertainment System](https://engineering.verygood.ventures/resources/airplane_entertainment_system/) | Reference for repository/view composition; its multi-tab navigation is unnecessary here today |

## Completion criteria for the refactoring program

- The existing review failure is fixed and all package/app quality checks pass in CI.
- Practice modes, attempts, completion, save failures, and async ordering have named contracts and focused tests.
- Question eligibility, section metadata, elapsed-time formatting, and semantic styling each have one maintained implementation.
- Feature views can be tested without production persistence and contain no catalog filtering or storage mutation logic.
- Corpus generation and schema evolution are reproducible and documented.
- New packages and abstractions are introduced for demonstrated reuse or ownership needs, with the cost justified in the PR.

## Recommended order of refactoring efforts

Use the following order as the default execution backlog. It expands the earlier stages into individual efforts, putting a reliable baseline first, then session correctness, reusable presentation, and data/tooling improvements. Each effort should remain a focused PR or a short series of PRs.

| Order | Effort | Why it belongs here |
| --- | --- | --- |
| 1 | **R01 — Separate review attempts from saved answer selections** | Fix the demonstrated failure first so subsequent changes have a trustworthy behavioral baseline. Keep this fix focused; the broader session redesign follows. |
| 2 | **R27 — Remove tracked build caches and standardize ignore rules** | Make normal test runs leave clean diffs before introducing more verification and generated-output checks. |
| 3 | **R22 — Establish a shared quality gate across all packages** | Fix the current lint and establish the root verification command and CI. Add generator checks as those workflows become reproducible; broader lint adoption can be a separate PR. |
| 4 | **R21 — Refactor test organization and asynchronous assertions** | Establish the shared test harness and controlled async fakes needed by the upcoming changes. Migrate touched tests incrementally so a wholesale test rewrite does not delay correctness fixes. |
| 5 | **R04 — Replace mode booleans with typed session configuration** | Give subsequent policies and transitions one explicit representation of the kind of session being run. |
| 6 | **R05 — Extract question eligibility and selection policies** | Centralize review/pending rules before changing batching, completion, and counts. |
| 7 | **R15 — Make state snapshots immutable and equality consistent** | Clarify attempts versus distinct-question results and ensure async handlers work with stable snapshots. |
| 8 | **R11 — Consolidate dependency creation and resource ownership** | Make dependency lifetimes predictable before changing subscriptions, cancellation, and feature controllers. |
| 9 | **R02 — Define BLoC concurrency and stale-result rules** | Protect the newly explicit session state from overlapping loads, saves, and navigation. |
| 10 | **R03 — Model saving and failure recovery explicitly** | Build retry and failure behavior on those ordering guarantees, distinguishing failed writes from failed refreshes. |
| 11 | **R06 — Give pending batches an explicit result contract** | Reuse the session configuration, eligibility rules, and async/error conventions to make refill and exhaustion reliable. |
| 12 | **R10 — Make initialization and observation contracts consistent** | Reconcile initial reads and live updates before additional features adopt the storage streams. |
| 13 | **R07 — Centralize navigation, completion, and exit policies** | Define terminal actions using the settled session, saving, and exhaustion states. Resolve the skipped-question policy in this effort. |
| 14 | **R08 — Use one session clock and elapsed-time formatter** | Align elapsed-time ownership with the session start, retry, completion, and exit boundaries. |
| 15 | **R09 — Put history and settings operations behind feature state** | Apply the established dependency, observation, and failure conventions to the remaining storage-driven views. |
| 16 | **R16 — Separate answer identity from shuffled presentation** | Establish a stable answer-presentation API before extracting the widgets that consume it. |
| 17 | **R12 — Split large page libraries by responsibility** | Extract widgets and views after their policy and storage responsibilities have moved to clear owners. |
| 18 | **R14 — Centralize theme tokens and answer-status presentation** | Give the extracted components a consistent visual vocabulary before consolidating shared screen states. |
| 19 | **R13 — Share loading, error, and empty-state presentation** | Reuse the settled failure semantics and theme tokens in a small set of app-local components. |
| 20 | **R24 — Finish localization, semantics, and responsive layout cleanup** | Verify the consolidated presentation with localized messages, accessible status, narrow layouts, and large text. |
| 21 | **R17 — Add a reusable catalog and validated section metadata** | Consolidate data loading and lookup once consumers have explicit selection and presentation contracts. |
| 22 | **R19 — Make question-asset compilation reproducible** | Reuse the canonical section metadata and connect deterministic compilation checks to CI. |
| 23 | **R20 — Specify persistence invariants and migration workflow** | Formalize storage evolution against the settled attempt/session model and bank identity rules. Any schema change needed by an earlier effort must bring its migration work forward. |
| 24 | **R25 — Centralize app metadata and build configuration** | Remove version and release-configuration drift once the shared build/verification workflow is established. Bring release-critical configuration forward if distribution is imminent. |
| 25 | **R23 — Replace template documentation with project guidance** | Complete an onboarding pass against the implemented architecture and commands. Update contracts and decisions during every preceding effort rather than waiting until this step. |
| 26 | **R18 — Separate pure domain APIs from Flutter and serialization** | Reassess package boundaries after logical responsibilities are stable. Fix misleading documentation and unsafe construction boundaries earlier when touched; undertake a package split only for a concrete reuse or isolation need. |
| 27 | **R26 — Bound work on large histories and long practice sessions** | Optimize after duplication and ownership issues are resolved, using measurements to decide which remaining costs justify added complexity. |

Tests and documentation travel with each behavior change, regardless of where R21 and R23 appear in the sequence. The final two efforts are conditional: record the reason for deferring them if no reuse requirement or measured performance issue warrants the work. Before each PR, use that effort's “Done when” criteria and run the relevant checks; retain the all-package CI gate throughout.
