# Agent guide: Preguntas Mercancías

Offline Flutter app (Android + web) for studying the Spanish mercancías
question bank. Monorepo: `pm_app/`, `widgetbook/`, and three packages under
`packages/`. The [README](README.md) is the full human guide; this file is the
short list of things an agent must not get wrong. Each package has its own
`CLAUDE.md` with package-specific rules.

## Commands

All Flutter/Dart commands go through FVM (Flutter pinned in `.fvmrc`).

| Task | Command (from repo root) |
| --- | --- |
| Set up a fresh checkout or worktree | `./tool/bootstrap.sh` |
| Fast check of what you changed | `fvm exec ./tool/verify.sh --changed` |
| Check specific packages | `fvm exec ./tool/verify.sh --only pm_app --only packages/pm_persistence` |
| Full quality gate (same as CI) | `fvm exec ./tool/verify.sh` |
| Regenerate all checked-in generated code | `fvm exec ./tool/regen.sh` |
| One test file | `cd pm_app && fvm flutter test test/src/practice/bloc/practice_bloc_test.dart` |

Run at least `--changed` before saying a task is done. CI runs the full gate.

## Never edit by hand

A hook in `.claude/settings.json` blocks these; regenerate instead.

| Path | Source of truth | Regenerate with |
| --- | --- | --- |
| `packages/pm_questions_bank/assets/pm_260326_json/` | `packages/pm_questions_bank/assets/pm_260326/*.txt` | `tool/regen.sh` |
| `packages/pm_persistence/lib/src/database/*.g.dart` | `pm_persistence_database.dart` | `tool/regen.sh` |
| `pm_app/lib/l10n/app_localizations*.dart` | `pm_app/lib/l10n/app_es.arb` | `tool/regen.sh` |
| `pm_260326/` (repo root) | Archival upstream copy. Not read by anything. Fix questions in the package assets instead. | — |

Commit generated output in the same change as its source.

## Rules that look incidental but are decisions

Read the ADR before changing the related code. A behavior change must update
the ADR (or add a new one) and its tests in the same change.

- Review retries stay open until answered correctly. See [ADR 0001](docs/decisions/0001-review-retry-semantics.md).
- Mastery is "ever correct" and sticky. See [ADR 0002](docs/decisions/0002-ever-correct-progress.md).
- Completion comes from `PracticeSessionConfig`. Never add boolean mode flags. See [ADR 0003](docs/decisions/0003-session-completion.md).
- Every schema change needs a forward migration and a migration test. See [ADR 0004](docs/decisions/0004-persistence-versioning.md).
- `pm_questions` is pure Dart. No Flutter imports. See [ADR 0005](docs/decisions/0005-question-domain-boundaries.md).

Smaller choices (the reason for a pattern, a rejected alternative) go in
[docs/decisions/log.md](docs/decisions/log.md), one dated line each.

## Code conventions

- Feature-first layout under `pm_app/lib/src/<feature>/` with a page, view,
  widgets and `bloc/` side by side.
- User-facing strings go in `app_es.arb`. Spanish is the only locale.
- New widgets that `pm_app` exposes through `component_library.dart` get a Widgetbook use case.
- Behavior changes need tests. Run tests in random order (the gate already does).

## Working in parallel

Several agents may work in this repo at the same time. Read
[docs/workflow.md](docs/workflow.md) before you start. In short:

- One task per git worktree and branch. Run `./tool/bootstrap.sh` in a new worktree.
- Work is tracked in GitHub Issues (`gh issue list`). Claim an issue before you
  start and reference it in commits: `feat(practice): … (#12)`.
- Shared hotspots (`pm_app/lib/src/app/`, `pm_app/lib/src/navigation/`,
  Drift schema, `app_es.arb`, `tool/`) conflict easily. Keep those edits small and rebase often.
- On a conflict in a generated file, take either side, then run `tool/regen.sh`.

## Where knowledge lives

| Kind | Location |
| --- | --- |
| Product and architecture decisions | `docs/decisions/` (ADRs and the decision log) |
| Design proposals for upcoming work | `plans/` (see `plans/README.md` for the lifecycle) |
| Who is doing what | GitHub Issues |
| How to do recurring tasks | `.claude/skills/` |
| Measurements | `docs/performance/` |
| One person's preferences | Personal Claude memory, not the repo |

If you learn something that the next agent would get wrong, add it to the right
file above in the same change.
