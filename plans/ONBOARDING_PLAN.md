---
status: active
updated: 2026-11-06
issue: "#1 (O01), #2 (O02), #3 (O03), #5 (O04)"
---

# Plan: first-launch onboarding

A short, skippable sequence of pages shown on first launch. It explains what
the app is, what problem it solves for someone preparing the mercancías exam,
and how the app's study loop solves it. After that the user lands on home.

## 1. Goals and non-goals

Goals:

- A new user understands in under 30 seconds what the app contains and how to
  study with it.
- Onboarding shows once. It is never a gate: the user can skip it, and a
  storage failure must never keep them out of the app.
- In debug builds, a developer can replay it from Settings to test it.

Non-goals:

- No account, no permissions, no data collection. The app stays offline.
- No configuration steps (such as picking sections or setting a daily goal).
  These can come later as separate pages, but they are out of scope here.
- No per-page artwork, no mascot. All pages share one illustration: a
  line-art truck that drives from page to page (O04, §4 "Illustration").
  The product owner chose a sober look for adult professionals over
  characters or cartoon art.

## 2. Content (draft copy, Spanish)

Four pages. The copy was approved by the product owner on 2026-11-06.

| # | Purpose | Title | Body |
| --- | --- | --- | --- |
| 1 | What it is, and the problem | Prepara el examen de mercancías | Todas las preguntas del banco oficial, organizadas por materias, en tu bolsillo. Sin papeles ni apuntes sueltos. |
| 2 | Practice | Practica a tu ritmo | Responde por materias y continúa donde lo dejaste. Cada pregunta indica la norma en la que se basa. |
| 3 | Review loop (ADR 0001, ADR 0002) | Los fallos vuelven hasta que los aciertas | Las preguntas que fallas se repiten hasta que las respondes bien. Tu progreso muestra lo que ya dominas y lo que te queda. |
| 4 | Exam readiness and offline | Ponte a prueba | Haz simulacros de 30 preguntas como en el examen. Todo funciona sin conexión y tus datos se quedan en tu dispositivo. |

Controls: a back arrow (tooltip "Atrás") top left on pages 2–4, "Saltar" top
right on pages 1–3, and one full-width main button at the bottom: "Siguiente",
or "Empezar" on the last page. A page indicator shows where the user is. Swiping works in both directions with touch, mouse and trackpad (Flutter
drags only with touch by default, which breaks swiping on web). The system back
button goes to the previous page before it leaves onboarding.

Every claim must match current behavior. If a claim stops being true (for
example, the question count or the simulacro length), update the copy in the
same change.

## 3. Behavior

| Situation | Result |
| --- | --- |
| First launch, flag not set | Onboarding, then home |
| "Saltar" or "Empezar" | Persist `onboardingCompleted = true`, replace the route with home |
| Flag set | Straight to home |
| Settings still loading | `AppLoadingIndicator` (already shown today while settings load) |
| Reading the flag fails | Home. Never block the app on a preferences error. |
| Writing the flag fails | Still go to home. Onboarding may show again on the next launch, which is acceptable. |
| Settings › "Ver introducción" (debug builds only, `kDebugMode`) | Push onboarding. Finishing it pops back to Settings. The flag is not touched. |

There are no existing users yet, so no upgrade behavior is needed. An install
without the flag sees onboarding.

## 4. Architecture

New feature folder, following the feature-first layout:

```text
pm_app/lib/src/onboarding/
  onboarding_page.dart          # route entry; takes an onFinished callback
  onboarding_gate.dart          # picks onboarding or home from SettingsBloc state
  onboarding_steps.dart         # the ordered list of OnboardingStep value objects (l10n getters)
  view/onboarding_view.dart     # PageView, controls, page indicator
  widgets/onboarding_step_view.dart
  widgets/onboarding_page_indicator.dart
  widgets/onboarding_road.dart  # shared illustration: fixed truck, scrolling road (O04)
```

- **State.** The current page index belongs to the `PageController`. It is
  ephemeral UI state, so there is no BLoC for it. Completion is app-wide state
  and goes through `SettingsBloc`.
- **Persistence.** Add the flag to `SettingsStore` in `pm_persistence`, backed
  by shared_preferences key `onboarding_completed` (default `false`). This
  needs no Drift schema change, so ADR 0004 does not apply. Add
  `loadOnboardingCompleted()` and `setOnboardingCompleted(bool)`. No watch
  stream: only the gate reads the flag, and only `SettingsBloc` writes it.
- **SettingsBloc.** `SettingsLoaded` gains `onboardingCompleted`. A new
  `OnboardingCompleted` event emits the completed state first, then writes
  through the store (a failed write goes to `addError`), so the gate always
  moves on.
- **Widgetbook.** `component_library.dart` exports `OnboardingView`,
  `OnboardingStep` and `onboardingSteps`. One use case shows the real flow.
- **Gate.** In `app.dart`, `home:` becomes `OnboardingGate`. It builds
  `QuestionHomePage` or `OnboardingPage` from `SettingsBloc` state. Because the
  gate rebuilds when the state changes, completing onboarding needs no
  navigation call.
- **Settings entry point.** In debug builds only (`kDebugMode`), a
  "Ver introducción" list tile pushes `OnboardingPage(onFinished: () => AppNavigator.pop(context))`
  through `AppNavigator`. Release builds don't show it.
- **Illustration (O04).** A full-width band in `primaryContainer` fills the
  top of the screen, behind the status bar and the back and skip buttons. It
  aims for two thirds of the screen height but always leaves 240 for the page
  text. One `OnboardingRoad` scene sits in the band, on top of the
  `PageView` and behind `IgnorePointer`, so it stays still while the pages
  slide and drags fall through to the `PageView`. Each page leaves the band's
  height empty at the top, then shows its title and body at most 320 wide so
  the body keeps the title's measure. The scene fills the band without a
  background of its own; the truck sits near the bottom, centred, scaled to
  fit both width and height. It reads the fractional `PageController.page`:
  the road and one milestone per page scroll by one window width per page,
  and the wheels turn by distance / radius so they roll without slipping. The
  body bobs slightly between pages, except when
  `MediaQuery.disableAnimations` is on. Assets: `truck_body.svg` (lines plus a
  white fill silhouette, so the road doesn't show through) and
  `truck_wheel.svg` (centred, with lug nuts so rotation is visible), both
  split from `assets/onboarding/source/truck.svg`, which isn't bundled.

Hotspots touched: `lib/app.dart` (app shell), `app_es.arb`, and the
`SettingsStore` public API (not the schema). Keep each one in a separate,
small item so the PRs rebase easily.

## 5. Items

| ID | Item | Packages | Hotspot |
| --- | --- | --- | --- |
| O01 | `SettingsStore` onboarding flag, shared_preferences implementation, store tests, `FakeSettingsStore` update | `pm_persistence`, `pm_app/test/helpers` | — |
| O02 | Onboarding feature (steps, view, widgets), `SettingsBloc` event and state, `OnboardingGate` in `app.dart`, ARB strings, Widgetbook use cases | `pm_app`, `widgetbook` | `app-shell`, `l10n` |
| O03 | Debug-only Settings › "Ver introducción" | `pm_app` | `l10n` |
| O04 | Shared truck illustration (`OnboardingRoad`), `flutter_svg`, assets, Widgetbook use case | `pm_app`, `widgetbook` | — |

O02 depends on O01. O03 depends on O02. O04 depends on O02 (stacked on O03's branch, which has the latest view).

## 6. Tests

- O01: the default is `false`, a set value persists across instances, and a
  failed write throws. This mirrors the existing answer-shuffle tests.
- O02:
  - `SettingsBloc`: the loaded state carries the flag; `OnboardingCompleted`
    persists and emits; a failed write still emits completed.
  - `OnboardingGate`: shows a loader while settings load, onboarding when the
    flag is unset, home when it is set, and home on a load failure.
  - `OnboardingView`: "Siguiente" advances, swiping advances, "Saltar" and
    "Empezar" finish, the indicator follows the page, and the last page shows
    no "Saltar".
  - Full-app journey: fresh install, then onboarding, "Empezar", then home.
    Relaunching goes straight to home.
- O03: in debug, the tile pushes onboarding, finishing it returns to Settings,
  and the flag is unchanged. The tile is hidden when the debug check is false.
  Inject the check, so the test doesn't depend on the build mode.

## 7. Product answers (2026-11-06)

1. The copy in §2 is approved as written.
2. There are no existing users, so upgrade behavior is out of scope.
3. Four pages.
4. Use placeholders where the illustrations will go. Art comes later.
   Superseded by O04: one shared truck illustration, no mascot (2026-11-06).
5. Replay from Settings only in debug builds (`kDebugMode`).

## 8. Decisions to record in the implementing PRs

- Decision log: the onboarding flag lives in shared_preferences through
  `SettingsStore`, not in Drift. Why: it is a device preference, not study
  data, and it needs no migration.
- Decision log: onboarding never blocks the app. Read or write failures fall
  through to home.
