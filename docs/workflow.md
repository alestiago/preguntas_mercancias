# Working in parallel

How several people or agents can work in this repository at the same time
without stepping on each other. [CLAUDE.md](../CLAUDE.md) has the short
version.

## 1. Pick and claim a task

Work is tracked in GitHub Issues. [plans/backlog.md](../plans/backlog.md)
indexes the R/A items until each one has an issue.

```sh
gh issue list --label status:ready
gh issue edit <N> --add-label status:in-progress --remove-label status:ready --add-assignee @me
```

- Claim one issue per branch. If it isn't labeled `status:ready`, ask first.
- If an issue carries a `hotspot:*` label, check that no other open PR has the
  same label before you start.
- A task without an issue gets one first. The issue template asks for the
  scope, the affected packages, and any ADR involved.

## 2. Isolate the work in a worktree

Each task gets its own git worktree and branch, so parallel agents never share
a working directory, `.dart_tool/` or build output.

```sh
# Claude Code: start an isolated session
claude --worktree <short-name>

# Or with plain git
git worktree add ../pm-<short-name> -b <type>/<issue>-<short-name> origin/main
cd ../pm-<short-name>
./tool/bootstrap.sh
```

Branch names look like `<type>/<issue>-<slug>`, for example
`feat/12-pending-retry` or `refactor/A07-freezed-trial`.

Remove the worktree when its PR is merged: `git worktree remove <path>`.

## 3. Verify at the right scope

| When | Command |
| --- | --- |
| While iterating | One test file: `fvm flutter test path/to/test.dart` |
| Before each commit | `fvm exec ./tool/verify.sh --changed` |
| Before opening a PR, or when touching `tool/` or a shared package | `fvm exec ./tool/verify.sh` |

`--changed` checks the packages you touched plus everything that depends on
them (a change to `pm_questions` re-checks all of them). CI always runs the
full gate.

## 4. Divide work by package

The package boundaries are also the safest lines for splitting parallel work.

| Area | Runs safely in parallel? |
| --- | --- |
| `packages/pm_questions` (pure domain) | Yes, but every other package depends on it. Keep public API changes in their own PR. |
| `packages/pm_questions_bank` corpus edits | Yes, if each task edits different sections (`pm1A`…`pm1H`) |
| `packages/pm_persistence` | One schema change at a time (`hotspot:schema`) |
| `pm_app/lib/src/<feature>/` | Yes, one feature per task |
| `pm_app/lib/src/app/`, `src/navigation/` | Shared. Keep edits small (`hotspot:app-shell`) |
| `pm_app/lib/l10n/app_es.arb` | Conflicts often but resolves easily. Rebase often (`hotspot:l10n`) |
| `widgetbook/` | Yes. It follows `pm_app` widget changes. |
| `tool/`, `.github/`, root config | One at a time (`hotspot:tooling`) |

## 5. Generated files and conflicts

Generated output is committed (see the README). On a rebase or merge conflict
in any of these files:

- `packages/pm_questions_bank/assets/pm_260326_json/*`
- `packages/pm_persistence/lib/src/database/*.g.dart`
- `pm_app/lib/l10n/app_localizations*.dart`

**don't merge them by hand.** Resolve the *source* conflict (the `.txt`
corpus, the schema `.dart` file or `app_es.arb`) first. Then:

```sh
git checkout --theirs -- <generated paths>   # either side works
fvm exec ./tool/regen.sh
git add <generated paths>
```

`bootstrap.sh` turns on `git rerere`, so git remembers conflict resolutions
you repeat across rebases. `.gitattributes` marks these files as generated, so
GitHub collapses them in PR diffs.

## 6. Commits and PRs

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/),
with the issue or item ID:

```text
feat(practice): keep review question open after wrong answer (#12)
refactor(persistence): extract migration helpers (R20)
docs(adr): supersede 0003 with explicit pending completion (#18)
```

Scopes: `practice`, `home`, `history`, `settings`, `summary`, `app`, `nav`,
`l10n`, `persistence`, `questions`, `bank`, `widgetbook`, `tool`, `ci`, `adr`,
`docs`.

- Keep each PR to one issue, small enough to review in one sitting.
- Rebase on `origin/main` before opening a PR and again before merging. Never
  force-push to `main`.
- The PR template asks about decision impact. If behavior governed by an ADR
  changes, the same PR updates the ADR.
- When a PR merges, close the issue (`Closes #N` in the PR body) and update
  [plans/backlog.md](../plans/backlog.md) if the item is listed there.

## 7. Leave context for the next agent

Before finishing a task, ask what the next person would get wrong without
knowing what you learned. Then put it in the right place:

| Learned… | Put it in… |
| --- | --- |
| A product or architecture rule | A new or updated ADR in `docs/decisions/` |
| Why something is done a certain way, or an alternative you rejected | A line in `docs/decisions/log.md` |
| A pitfall specific to one package | That package's `CLAUDE.md` |
| A repeatable procedure | A skill in `.claude/skills/` |
| Progress on a multi-step task | A comment on the issue |
