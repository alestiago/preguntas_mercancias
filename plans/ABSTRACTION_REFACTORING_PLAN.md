# Abstraction and simplification plan

Reviewed **2026-09-19**, against **`b5be853`**. This is a proposed follow-up to the recent refactoring, based on the current implementation rather than the earlier refactoring backlog. No application changes or dependency installations are included.

The best remaining opportunities are a shared question catalog, a coherent session-launch contract, a smaller session model, and simpler stream ownership. Favor small value objects, composition, and existing BLoC facilities. Introduce an abstract interface where implementations actually vary; most of the opportunities below do not need inheritance.

## Baseline and evaluation

Handwritten Dart library sizes, excluding generated files and localization:

| Area | Files | Lines |
| --- | ---: | ---: |
| `pm_app/lib` | 53 | 5,655 |
| `packages/pm_questions/lib` | 5 | 399 |
| `packages/pm_questions_bank/lib` | 2 | 64 |
| `packages/pm_persistence/lib` | 12 | 572 |

The largest remaining concentration is practice: `practice_bloc.dart` is 420 lines, `practice_state.dart` 320, and `question_practice_view.dart` 481. File size alone is not a reason to introduce an abstraction: moving methods to another file does not reduce total complexity.

Already present and worth retaining: `QuestionProgressStore`, `SettingsStore`, `PracticeSessionClock`, `PracticeSessionConfig`, `PracticeQuestionPolicy`, `QuestionAnswerPresentation`, dependency ownership, shared loading/message widgets, and the pure question-domain package. The plan extends these boundaries instead of recreating them.

Priorities: **P1** = strongest next candidates; **P2** = useful focused follow-ups; **P3** = conditional. Effort: **S** = local change; **M** = feature and tests; **L** = several contracts. Payoffs are source-based judgments, not measured savings. Each implementation should report net handwritten lines, generated lines separately, and which duplicated responsibilities disappeared. Do not add the potential savings of overlapping entries together.

| ID | Priority | Effort | Concept | Expected payoff |
| --- | --- | --- | --- | --- |
| A01 | P1 | M | Immutable `QuestionCatalog` and a cached loading boundary | Shared lookup/grouping; simpler consumers; may initially add lines |
| A02 | P2 | S | One bank manifest | Remove repeated section and asset metadata |
| A03 | P1 | M | `PracticeLaunch` and session question source | Remove loader construction from home state and repeated route setup |
| A04 | P1 | L | Session answers and pure transitions | Reduce BLoC/state coupling; line reduction depends on design |
| A05 | P2 | S–M | Mode capabilities and pending options | Remove repeated mode checks and irrelevant constructor defaults |
| A06 | P1 | M | Event-owned stream subscriptions | Remove subscription plumbing and redundant history reads |
| A07 | P2 | M | Generated immutable state/data classes | Strongest candidate for fewer handwritten boilerplate lines |
| A08 | P3 | S–M | Observable persisted preference | Replace manual current-value replay if a trial is smaller |
| A09 | P2 | M | Typed answer-commit outcome | Simplify failure reasoning; likely adds lines initially |
| A10 | P2 | S | Shared question-status badge | Small, direct widget duplication reduction |

## Enumerated opportunities

### A01 — Share an immutable question catalog

**Evidence:** [question loading](../pm_app/lib/src/questions/load_questions.dart), [home state](../pm_app/lib/src/home/bloc/home_state.dart), [history BLoC](../pm_app/lib/src/history/bloc/answer_history_bloc.dart), and [simulacro selection](../pm_app/lib/src/questions/draw_simulacro_questions.dart).

`loadQuestionsFromBank` constructs a loader on every call; the loader decodes and validates section JSON each time. Home owns a full question list, history builds `_questionsByCode`, and simulacro selection repeatedly filters that list by section. These are different views of the same catalog.

**Proposed concept:** a pure, immutable `QuestionCatalog` containing ordered questions, `byCode`, and `bySection`. Keep lifetime progress outside it. Place reusable catalog data in `pm_questions`; asset loading remains in `pm_questions_bank`, and app composition owns caching. Begin with an injected `Future<QuestionCatalog> Function()`; add a `QuestionCatalogSource` interface only if multiple operations or adapters justify it.

**Steps:**

1. Build and validate the indexes once, defining duplicate-code rejection explicitly.
2. Share a successful catalog load and concurrent in-flight loads at the composition boundary. Clear a failed load so retry remains possible.
3. Replace history indexing and simulacro pool construction with catalog access. Shuffle copies of section lists.
4. Let `PracticeQuestionPolicy` continue to own eligibility and lifetime-status rules.

**Reduction:** removes repeated indexing/grouping and list plumbing; a new catalog implementation may make the initial net line count neutral or positive. Reuse and ownership are the primary benefit. AssetBundle may already cache strings, so do not claim disk-I/O savings or a measured performance gain.

**Acceptance:** preserve catalog order, section selection, unknown historical-question fallback, balanced seeded sampling, and defensive immutability. Verify concurrent loads share work and failed loads can retry. Adapt the existing loader, home, history, and simulacro tests.

### A02 — Define section and edition metadata once

**Evidence:** [QuestionBankLoader](../packages/pm_questions_bank/lib/src/loaders/question_bank_loader.dart) declares both `sections` and `_assetPathBySection`; [the compiler](../packages/pm_questions_bank/tools/compile_question_assets.dart) repeats `_sections` and edition directories. [PracticeSectionSelector](../pm_app/lib/src/practice/widgets/practice_section_selector.dart) and simulacro selection import loader metadata.

**Proposed concept:** a small `QuestionBankManifest` with edition, ordered section codes, and deterministic source/runtime asset paths. Keep this bank-specific metadata in a Dart-only library inside `pm_questions_bank`, available to its Dart compiler without importing Flutter services. Pass section data to consumers instead of making them depend on the loader class.

**Reduction:** delete the duplicate section list and eight manually repeated runtime paths. Avoid a separate class per section or a schema-generation framework for eight codes.

**Acceptance:** compiler output is byte-for-byte unchanged; every manifest section loads; unknown sections still fail clearly; the pure domain does not acquire bank-specific metadata or Flutter imports. Preserve the package boundaries in [ADR 0005](decisions/0005-question-domain-boundaries.md).

### A03 — Make session launch a coherent value and source contract

**Evidence:** [HomeLoaded](../pm_app/lib/src/home/bloc/home_state.dart) exposes five session/loader factory methods. [QuestionHomeView](../pm_app/lib/src/home/view/question_home_view.dart) assembles configuration and callbacks for three practice modes; [AnswerHistoryView](../pm_app/lib/src/history/view/answer_history_view.dart) creates another inline loader. [QuestionPracticePage](../pm_app/lib/src/practice/practice_page.dart) accepts configuration and two independently supplied loader callbacks.

**Proposed concept:** `PracticeLaunch(config, source)`, built by a small `PracticeLaunchFactory`. Use one `SessionQuestionSource` interface with a batch request carrying section, excluded codes, latest progress, and requested size. Supply a fixed source for simulacro/single-question sessions and a catalog-backed source for standard/review/pending practice. Reuse or rename `PendingQuestionBatch` as the shared result with `questions` and `hasMore`.

The source selects candidates by delegating to the existing policy; it must not own navigation, save state, or routing. Non-pending sources return a complete set with `hasMore: false`. Enforce valid config/source combinations through launch constructors or the factory.

**Steps:** move loader factories out of `HomeLoaded`; snapshot the shuffle setting once when launching; pass one launch value through page construction; use the same batch contract for initial pending load and refills. With A01, selection can use the latest progress rather than callbacks closed over an old home snapshot. Preserve BLoC-side validation against progress changes while a batch is loading.

**Reduction:** removes state-owned closures, repeated launch wiring, and the initial-load/refill contract mismatch. Keep `AppNavigator` as the small route helper it already is.

**Acceptance:** all five modes retain their current behavior; pending initial load reports exhaustion accurately; refills exclude loaded codes and reject a non-advancing source; shuffled answers remain stable; history can launch a fixed single question. Keep seedable simulacro selection.

### A04 — Give session answers and transitions one owner

**Evidence:** [PracticeLoaded](../pm_app/lib/src/practice/bloc/practice_state.dart) carries questions, two question-code maps, counters, cursor, progress, and transport status. Its `copyWith` reconstructs and normalizes collections even for cursor changes. [PracticeBloc](../pm_app/lib/src/practice/bloc/practice_bloc.dart) separately implements answer accounting, retry reopening, restart, append, and navigation. [PracticeSummary](../pm_app/lib/src/practice/practice_summary.dart) repeats the answer-map/counter vocabulary and question-result calculations.

**Proposed concepts:**

- `SessionQuestions`: immutable ordered questions plus stable answer presentations, rebuilt when questions are loaded/appended.
- `SessionAnswers`: retained selections and attempt totals, with operations such as `recordSelection` and `reopenReviewQuestion`.
- A small `PracticeSession` value exposing pure transitions such as `next`, `previous`, `jumpTo`, `restart`, and `appendBatch`, using the existing policy.

Begin with `SessionAnswers`; extract the other concepts only where they remove real branching or repeated construction. `PracticeLoaded` composes the session with load/save/refill status. The BLoC retains asynchronous I/O, event concurrency, and stale-session guards. Build the summary from a frozen session result instead of collecting unrelated fields in the view.

**Reduction:** centralizes transitions and reduces parameters repeated across constructors and `copyWith`. This is a complexity refactor, not an assured total-line reduction. Avoid a second mutable controller that competes with BLoC state.

**Acceptance:** retain [review retry semantics](decisions/0001-review-retry-semantics.md): removing a selection must not decrement attempt totals. Preserve [completion rules](decisions/0003-session-completion.md), skipped-question summaries, stable presentation after navigation, immutable inputs, and stale-result tests. Reuse unchanged immutable question data on navigation. Rerun the [navigation benchmark](performance/R26.md) if transition algorithms change.

### A05 — Finish centralizing mode capabilities

**Evidence:** [PracticeSessionConfig](../pm_app/lib/src/practice/practice_session_config.dart) repeats pending defaults in four non-pending constructors. The [practice view](../pm_app/lib/src/practice/view/question_practice_view.dart) repeats the same section-selector condition in empty and populated states and switches modes for completion routing. The [app bar](../pm_app/lib/src/practice/widgets/practice_page_app_bar.dart) makes additional mode decisions.

**Proposed concept:** extend the existing config with derived capabilities such as `allowsSectionSelection`, `showsElapsedTime`, and `completionDestination`. Bundle batch size, threshold, and optional initial totals into validated `PendingPracticeOptions`, present only for pending mode. Alternatively use sealed config variants if a trial is simpler; do not introduce both a strategy hierarchy and a parallel capability object.

**Reduction:** removes duplicated mode comparisons and irrelevant pending initialization. Keep dynamic decisions such as exit confirmation, saving locks, and eligibility exhaustion on session state; they cannot be inferred from static mode capabilities alone.

**Acceptance:** table-driven tests cover all five modes, especially single-question versus simulacro completion routing and empty-state section selection. Preserve the meaning of pending totals as launch-time display metadata, distinct from current eligibility.

### A06 — Let BLoC handlers own observed streams

**Evidence:** [HomeBloc](../pm_app/lib/src/home/bloc/home_bloc.dart), [SettingsBloc](../pm_app/lib/src/settings/bloc/settings_bloc.dart), and [AnswerHistoryBloc](../pm_app/lib/src/history/bloc/answer_history_bloc.dart) manually subscribe, convert callbacks to private events, map errors, and cancel in `close`. History retry and load-more both cancel observation, read a prefix, then start a watcher that already promises an initial prefix.

**Proposed concept:** an observation-request handler that awaits/returns `emit.forEach`, with `onData` and `onError` mapping to feature states. BLoC already provides this subscription lifecycle. [Emitter.forEach documentation](https://pub.dev/documentation/bloc/latest/bloc/Emitter/forEach.html).

Start with history: translate start, retry, and increasing the visible limit into a common observation request. Register replacement requests in one `restartable()` event bucket, so a new request replaces the old watcher. Remove the explicit read-before-watch only after preserving loading/error behavior. `bloc_concurrency` is already installed and provides the transformer. [Package documentation](https://pub.dev/packages/bloc_concurrency).

Then simplify settings observation. Home is less mechanical because it joins catalog loading and live progress: retain its readiness coordination unless A01/A03 make one combined observation straightforward.

**Reduction:** likely deletes private data/error event types, subscription fields, manual cancellation, and duplicated history request code. Prefer this to a generic `BaseBloc<T>` with feature-specific override hooks.

**Acceptance:** latest history request wins; one active watcher; close and retry release it; errors remain reportable; local-date grouping and missing-question rows are unchanged. Preserve the existing cancellation-cleanup behavior with a delayed-cancel test. Keep newest-first bounded prefixes and insertion-ID tie ordering from [R26](performance/R26.md). A stream transformer does not undo started writes or replace practice's cross-event generation guards.

### A07 — Trial generated immutable data and state classes

**Evidence:** [practice state](../pm_app/lib/src/practice/bloc/practice_state.dart), [history state](../pm_app/lib/src/history/bloc/answer_history_state.dart), [settings state](../pm_app/lib/src/settings/bloc/settings_state.dart), and [reset state](../pm_app/lib/src/settings/cubit/progress_reset_cubit.dart) repeat fields, constructors, equality lists, and copying. Equatable already handles equality comparison, but maintaining `props` and `copyWith` remains manual.

**Package option:** Freezed generates immutable data classes/unions, equality, and copying. It needs `freezed_annotation`, a generator, and `build_runner`; JSON generation is optional and unnecessary for these states. [Freezed documentation](https://pub.dev/packages/freezed).

**Trial:** convert history state first and measure the net handwritten reduction. If useful, apply it to the smaller session values from A04 and configuration from A05. Avoid converting every model before those shapes settle. Keep feature-specific sealed states rather than flattening practice/refill/reset semantics into one generic loading enum.

**Tradeoffs:** generated repository lines will increase. Generation, analyzer compatibility, and review conventions become ongoing costs. Retain defensive copies at public construction boundaries: an unmodifiable collection view is not sufficient if the caller can still mutate the original input. Preserve runtime validation through construction and copying; do not replace release-mode checks with debug assertions.

**Acceptance:** existing equality/immutability tests pass, including mutation of original input collections. Copying must preserve invariants. Update [the verification script](../tool/verify.sh) to run app generation and check its outputs. Resolve versions against the pinned Flutter SDK and current lockfiles before adoption; no dependency compatibility trial was run for this plan.

### A08 — Replace manual preference replay only if it earns its dependency

**Evidence:** [SharedPreferencesSettingsStore](../packages/pm_persistence/lib/src/stores/shared_preferences_settings_store.dart) is 111 lines for one boolean, including a broadcast controller, cached initialization, a current value, revision tracking, cancellation, and `Stream.multi` replay.

**Proposed concept:** an observable persisted preference: initialize once, publish successful writes, replay the latest persisted value, and close once. RxDart's `BehaviorSubject` supplies latest-value replay to new subscribers. Use an unseeded subject until the stored value is known. [RxDart](https://pub.dev/packages/rxdart), [BehaviorSubject API](https://pub.dev/documentation/rxdart/latest/rx/BehaviorSubject-class.html).

**Reduction:** can remove manual subscription replay and some cached-value bookkeeping. It does not solve initialization/write ordering or persistence failures; keep explicit coordination and publish only after successful writes. Start locally inside the adapter. Extract a generic `PersistedPreference<T>` only when another setting actually needs it.

**Acceptance:** preserve the [existing store tests](../packages/pm_persistence/test/src/stores/shared_preferences_settings_store_test.dart) for writes during subscription startup, late subscribers, failed writes, and disposal; add a controlled initialization/write overlap case. Keep this P3 while there is only one setting, unless the implementation is clearly smaller after error handling is included.

### A09 — Model the answer commit boundary explicitly

**Evidence:** [PracticeBloc._onAnswerPressed](../pm_app/lib/src/practice/bloc/practice_bloc.dart) optimistically updates the selection/counters, then performs `recordAnswer` and `loadSnapshot` in one `try`. Both failures reach the same branch, which clears the recording flag and reports an error. [ProgressResetCubit](../pm_app/lib/src/settings/cubit/progress_reset_cubit.dart) already demonstrates explicit operation outcomes, but answer saving has only a boolean.

**Proposed concept:** a small `RecordPracticeAnswer` operation with a sealed outcome distinguishing uncommitted write failure, committed answer with refresh failure, and committed answer with refreshed progress. Pair it with explicit answer-save state. The BLoC uses A04's transitions to roll back an uncommitted optimistic selection or retain a committed one; refreshing after commit must not issue the write again.

**Reduction:** makes the persistence boundary and retry rules explicit, reducing reasoning complexity in the event handler. This likely adds lines and includes error-behavior work, so keep it a separate change from mechanical refactoring. A generic `Result<T>` alone does not express whether the answer committed. Do not introduce a general command bus for this operation.

**Acceptance:** controlled failures before commit and during refresh have distinct outcomes; duplicate taps persist once; navigation and exit retain their save lock; stale sessions cannot be overwritten. If a future adapter can fail after an ambiguous commit, define an idempotency contract before permitting blind write retries. No schema change is needed merely to separate the two current calls.

### A10 — Reuse the question-status badge

**Evidence:** [QuestionNavigationDrawer](../pm_app/lib/src/practice/widgets/question_navigation_drawer.dart) defines `_QuestionStatusIcon` and its style object. [PracticeSummaryPage](../pm_app/lib/src/practice_summary/practice_summary_page.dart) repeats the semantic label, avatar, color selection, and icon switch.

**Proposed concept:** a small `SessionQuestionStatusBadge` that reuses the existing localized-label extension and theme. Preserve the current difference in unanswered icons with a narrowly scoped parameter or named presentation variant.

**Reduction:** replace two implementations with one component and delete the private style class if its only remaining purpose is constructing that badge. No package is needed.

**Acceptance:** retain status semantics, colors, and current unanswered icons in both locations. Keep [PracticeProgressDivider](../pm_app/lib/src/practice/widgets/practice_progress_divider.dart) separate: it intentionally uses the same completed color for correct and incorrect answers and highlights the current position. Sharing that color rule with the badge would change behavior.

## Package choices

The package capabilities below were checked against their pub.dev documentation during this review. These are candidates, not an instruction to install all of them; package fit is this plan's assessment.

| Package | Decision for this repository |
| --- | --- |
| [bloc](https://pub.dev/documentation/bloc/latest/bloc/Emitter/forEach.html) + [bloc_concurrency](https://pub.dev/packages/bloc_concurrency) | Already direct dependencies. Use their existing stream-lifecycle and replacement primitives for A06 before adding a framework. |
| [freezed](https://pub.dev/packages/freezed) | Best candidate for handwritten state boilerplate reduction; trial in A07, retaining validation and defensive copies. |
| [rxdart](https://pub.dev/packages/rxdart) | Conditional A08 dependency for replay semantics. Do not add it solely to replace a few subscription lines already handled by BLoC. |
| [collection](https://pub.dev/packages/collection) | Optional small cleanup: `groupBy` can express history grouping or catalog section indexing. It preserves relative order within groups. It is not currently a direct app dependency; declare it if imported. Keep explicit loops when they encode validation, deduplication, or the balanced simulacro algorithm. [groupBy API](https://pub.dev/documentation/collection/latest/collection/groupBy.html). |

## Abstractions to defer

- **Generic base repositories or base BLoCs:** the two existing storage contracts have distinct semantics, and practice, history, and settings have different concurrency needs. A common ancestor would mostly add hooks and indirection.
- **A routing or dependency-injection framework:** the current route helper and constructor/provider injection are small. A03 addresses the actual launch duplication without replacing the app's infrastructure.
- **A universal async-state/page framework:** shared loading/message widgets already exist. Practice distinguishes initial loading, empty results, refill failure, exhaustion, and saving; flattening these loses useful information.
- **Generated JSON solely to reduce the codec:** the existing codec also enforces schema constraints. Mapping automation would not replace that validation, and [ADR 0005](decisions/0005-question-domain-boundaries.md) deliberately separates ingestion from domain models.
- **Generic pagination or a new drawer package:** only history currently needs a bounded persisted prefix. The drawer remains limited to 30-question simulacros; [R26](performance/R26.md) already documents why its eager implementation is retained.
- **Further package splitting or one strategy class per practice mode:** first consolidate the concrete concepts above; measure whether any remaining boundary needs an independently reusable package or implementation.

## Suggested execution sequence

1. **Small independent changes:** A10 and A02. Establish actual net deletion with limited behavioral risk.
2. **Stream simplification:** A06, history first, then settings; migrate home only if its readiness logic becomes simpler.
3. **Catalog and launch:** A01 followed by A03. These remove the strongest remaining ownership confusion between home state, views, and practice loading.
4. **Session concepts:** A05 and an incremental A04. Start with answers/counters; retain existing policies and concurrency guards.
5. **Data-class trial:** A07 after the session shapes settle. Continue only if the reduction merits generation overhead.
6. **Explicit persistence outcomes:** A09 as a separately reviewed behavior change. Bring it forward if save recovery is the next product priority.
7. **Conditional cleanup:** A08 and selective collection helpers after measuring their net value.

For implementation, run the affected existing tests and add tests for changed contracts or previously unrepresented failure sequences. Finish each implementation change with `fvm exec ./tool/verify.sh`; update generation checks if adopting Freezed. Preserve all accepted [architecture decisions](decisions/README.md).

This planning pass inspected source, manifests, relevant tests, architecture decisions, and existing performance notes. It did not execute Flutter tests, benchmarks, or package resolution, and does not claim a newly verified passing baseline.
