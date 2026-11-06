# Widgetbook implementation plan

## Goal

Create a standalone Flutter Widgetbook application at the repository root in
`widgetbook/`. It will render the real widgets from `pm_app` in isolation,
provide controls for the inputs that materially affect each widget, and make
interactive callbacks visible without navigating away from the use case.

The catalog source will mirror the production feature structure so that a
widget and its use cases are easy to find. For example:

```text
pm_app/lib/src/home/widgets/home_progress_summary.dart
    -> widgetbook/src/pm_app/lib/src/home/widgets/home_progress_summary.widgetbook.dart
```

The mirrored files contain fixtures and Widgetbook use cases only. They import
and exercise the production widgets; they must not copy their implementations.

## Proposed layout

```text
widgetbook/
├── analysis_options.yaml
├── pubspec.yaml
├── pubspec.lock
├── README.md
├── src/
│   ├── main.dart                            # Flutter entry point
│   ├── widgetbook_app.dart
│   ├── widgetbook_directories.dart          # manually registered catalog
│   ├── support/
│   │   ├── callback_notification.dart
│   │   ├── fixture_factory.dart
│   │   └── use_case_frame.dart
│   └── pm_app/                              # part of this Widgetbook app
│       └── lib/
│           └── src/
│               ├── app/widgets/
│               ├── home/widgets/
│               ├── history/widgets/
│               └── practice/widgets/
└── test/
    ├── callback_notification_test.dart
    └── widgetbook_app_test.dart
```

`widgetbook/src/pm_app/` is not a second package and does not have its own
`pubspec.yaml`; it is part of the Widgetbook application. Its `lib/src/`
subtree deliberately mirrors `pm_app/lib/src/`. Use-case files use the
`<production_name>.widgetbook.dart` suffix so they cannot be mistaken for
production implementations.

## Package and app setup

1. Create `widgetbook` as a separate Flutter package with web as its supported
   runner. Name the package something other than `widgetbook` (for example,
   `pm_widgetbook`) to avoid colliding with the dependency name.
2. Add `pm_app` as a path dependency (`../pm_app`). Add `widgetbook` and
   the normal Flutter test/lint dependencies. Resolve compatible versions
   against the repository's pinned Flutter SDK and commit the lockfile rather
   than putting speculative versions in this plan.
3. Keep `src/main.dart` as the Flutter entry point that runs the app defined in
   `src/widgetbook_app.dart`. Configure that app with
   `Widgetbook.material` and the directory tree from
   `src/widgetbook_directories.dart`.
4. Maintain the catalog with Widgetbook's manual `WidgetbookFolder`,
   `WidgetbookComponent`, and `WidgetbookUseCase` APIs. Manual registration is
   intentional here: it allows all catalog implementation files to remain at
   the requested `widgetbook/src/pm_app` path without introducing generator
   source-root configuration or proxy files under `lib/`. Widgetbook officially
   supports both manual and generated directory structures:
   [structure](https://docs.widgetbook.io/getting-started/structure).
5. Apply `AppTheme.light`, Spanish localization delegates, and the supported
   locales used by `pm_app`. Add viewport/device, text-scale, and theme controls
   where the resolved Widgetbook version supports them. This ensures use cases
   exercise the same theme extensions and localized labels as the app.
6. Add a small `widgetbook/README.md` with the resolve and run commands,
   including the pinned-SDK equivalents of:

   ```sh
   cd widgetbook
   fvm flutter pub get --enforce-lockfile
   fvm flutter run -d chrome -t src/main.dart
   ```

## Production import boundary

The Widgetbook package should not reach into another package through
`package:pm_app/src/...` imports. Add a narrow public library in `pm_app`, such
as `lib/component_library.dart`, that exports only:

- widgets selected for the catalog;
- public value types required by their constructors; and
- the app theme and localization configuration needed to render them.

Domain types that belong to `pm_questions` or `pm_persistence` should continue
to come from their owning packages. If Widgetbook needs to construct those
types directly, declare the owning package as a direct path dependency instead
of relying on a transitive dependency.

Do not broaden a production widget's API solely to make a use case easy to
write. Put sample-object construction in `widgetbook/src/support/fixture_factory.dart`.
If fixture setup exposes genuine UI/domain coupling—for example,
`HomeProgressSummary` requiring an entire `HomeLoaded` state for three
counts—record that as a separate refactoring candidate rather than mixing the
refactor into initial Widgetbook adoption.

## Use-case conventions

Each cataloged widget receives:

- a `Default` use case with representative app data;
- named boundary-state use cases when a knob cannot clearly express the state,
  such as `Empty`, `Loading`, `Error`, `Long text`, or `All answered`; and
- knobs only for arguments that help explain behavior.

Knobs are Widgetbook's interactive controls for changing use-case parameters
at runtime. Use integer controls for counts and indices, booleans for enabled or
loading flags, strings for user-visible copy, and segmented/drop-down controls
for enums and other short finite choices. See the official
[knobs overview](https://docs.widgetbook.io/knobs/overview).

Keep controls valid before constructing production objects. Examples:

- clamp `currentIndex` to the generated segment list;
- keep progress counts non-negative;
- ensure a selected answer exists in the fixture question;
- do not offer an `onTap`-enabled state that contradicts production behavior;
- give every knob a unique, user-facing label and a useful initial value.

Prefer a few meaningful controls over exposing every constructor argument.
Stable fixtures should supply incidental values such as question codes,
timestamps, and legal-reference copy.

## Callback feedback

All callbacks exposed by a use case must produce visible feedback. Flutter's
built-in Material mechanism for transient UI messages is
`ScaffoldMessenger.showSnackBar`; there is no separate Flutter SDK toast API.
Use it as the requested toast-style notification.

`callback_notification.dart` will provide one helper with a consistent message
format, for example:

```text
onStartReviewPractice called
onAnswer called with option B
onQuestionSelected called with index 3
```

`use_case_frame.dart` will place each interactive use case under its own
`Scaffold` and obtain a descendant `BuildContext`, ensuring the helper can find
the correct `ScaffoldMessenger`. Before showing a new `SnackBar`, hide the
current one so rapid interactions show the latest callback rather than building
a queue. Callback handlers remain local to the catalog and must not mutate
production persistence, navigation, or BLoCs.

For stateful demonstrations, the use-case wrapper may update local presentation
state as well as showing the notification. For example, selecting an answer can
update `selectedOption` and show `onAnswer called with option B`. The callback
notification remains mandatory even when the visual state already changes.

## Initial catalog

Implement the first pass in small groups. The priority is reusable leaf widgets
with explicit constructor arguments; full pages and BLoC-owned views come
later.

| Production widget | Initial use cases | Relevant controls | Callback notification |
| --- | --- | --- | --- |
| `HomeProgressSummary` | Default, no progress, all mastered, needs review | Correct, incorrect, and unanswered counts; construct a valid `HomeLoaded` fixture from them | All three start callbacks identify the selected practice mode |
| `AppMessagePanel` | Message only, actionable, long message | Message, icon choice, icon color, show action, action label | `onAction called` |
| `PracticeQuestionHeader` | Standard, navigator enabled, long title | Current question number, question count, navigator enabled | `onOpenQuestionNavigator called` |
| `PracticeQuestionPanel` | Unanswered, correct selection, incorrect selection | Fixture question, answer order, selected option | `onAnswer called with option …` and update local selection |
| `AnswerFeedbackSwitcher` | Hidden, correct, incorrect | Answered, selected option, answer order | None |
| `PracticeSessionFooter` | Next, finish, restart, disabled actions | Primary action, primary enabled, previous enabled | Distinguish primary and previous callbacks |
| `PracticeProgressDivider` | Start, in progress, completed | Segment statuses and current index | None |
| `SessionQuestionStatusBadge` | Navigation and summary variants for every status | Status and presentation variant | None |
| `PracticeSectionSelector` | All sections, selected section | Selected section | `onSectionSelected called with …` and update local selection |
| `ExitPracticeIconButton` | Default | No knob required | Show callback notification after the real confirmation flow resolves to exit |
| `AnswerHistoryDateHeader` | Today, yesterday, older date | Date fixture/preset | None |
| `AnswerHistoryList` | Populated, empty, loading more, missing question | Has more, loading more, row count | Distinguish load-more and selected-question callbacks |

The first implementation milestone is `HomeProgressSummary` plus the shared
support utilities. It proves the hardest parts early: localization, theme
extensions, aggregate domain fixtures, responsive wrapping, and multiple
callbacks. After that milestone passes, add the remaining widgets by feature.

Private implementation widgets such as `_ProgressStat` are represented through
their public parent rather than exported just for Widgetbook. Pages that require
repositories, BLoCs, clocks, routing, or persistence are explicitly outside the
initial catalog; add them only when there is a concrete need and a deterministic
fake dependency boundary.

## `HomeProgressSummary` fixture design

Its controls expose the three meaningful counts:

- `Correct questions`
- `Questions to review`
- `Pending questions`

The fixture factory builds enough questions and progress records to produce
those counts through the real `HomeLoaded` constructor. This keeps the use case
honest: its displayed values still come from the same policy used in the app.
Set sensible upper bounds on the integer controls to prevent an accidental
thousands-of-objects rebuild while dragging a knob.

The use case then passes three notification callbacks:

```dart
HomeProgressSummary(
  state: fixture,
  onStartSimulacroPractice: () => showCallback(
    context,
    'onStartSimulacroPractice called',
  ),
  onStartReviewPractice: () => showCallback(
    context,
    'onStartReviewPractice called',
  ),
  onStartPendingPractice: () => showCallback(
    context,
    'onStartPendingPractice called',
  ),
)
```

This use case must confirm the existing disabled behavior too: review and
pending cards should not invoke callbacks when their corresponding count is
zero, while simulacro remains interactive.

## Repository integration

Update `tool/verify.sh` so `widgetbook` participates as a Flutter package:

1. resolve its committed lockfile with `--enforce-lockfile`;
2. run `flutter analyze --no-pub`; and
3. run its Flutter tests in randomized order.

The existing repository-wide Dart formatting check will automatically include
Widgetbook sources once they are tracked. Update the root README repository map
and developer commands to mention the new catalog.

## Testing and acceptance criteria

Automated checks:

- a smoke test pumps the Widgetbook root and finds the manually registered
  catalog;
- fixture tests cover zero counts, mixed progress, and count limits;
- callback-helper tests tap an interactive sample and assert that the expected
  `SnackBar` text appears;
- focused widget tests cover any use-case wrapper that owns local state; and
- the repository quality gate completes successfully.

Manual checks on the web runner:

- the navigation tree follows the mirrored
  `src/pm_app/lib/src/<feature>/widgets` organization;
- every initial use case renders with the app's theme and Spanish strings;
- changing a knob immediately updates the rendered widget without exceptions;
- callback controls show the correct toast-style `SnackBar`;
- zero-count callbacks remain disabled where production behavior requires it;
- narrow and wide viewport presets reveal no unexpected overflow; and
- increased text scale and long-copy cases remain readable.

## Delivery sequence

1. Scaffold the standalone package, manual registry, theme/localization
   shell, and verification integration.
2. Add the narrow production export boundary and deterministic fixture factory.
3. Add `UseCaseFrame` and callback notification helpers with tests.
4. Deliver `HomeProgressSummary` use cases and validate responsive/callback
   behavior.
5. Add the remaining leaf-widget use cases feature by feature.
6. Update repository documentation and run the complete quality gate.

The work is complete when a clean checkout can resolve, analyze, test, and
launch the Widgetbook web app; `widgetbook/src/pm_app` remains part of that app;
the catalog renders the real production widgets; relevant arguments are
adjustable; and every callback is observable through a consistent in-UI
notification.
