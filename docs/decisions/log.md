# Decision log

Small decisions that don't warrant an ADR but would otherwise be lost: why a
pattern exists, an alternative that was rejected, a convention that was agreed.
Add new entries at the top, one or two lines each. Promote an entry to an ADR
when it starts to govern product behavior or stored data.

Format: `- YYYY-MM-DD: decision. Why. (refs: #issue, ADR, plan, commit)`

## Entries

- 2026-11-06: The onboarding-completed flag lives in shared_preferences behind `SettingsStore`, not in Drift. Why: it is a device preference, not study data, so it needs no schema migration and survives a progress reset. (refs: #1, plans/ONBOARDING_PLAN.md)
- 2026-11-06: Work tracking moves to GitHub Issues. Plans in `plans/` hold designs only and carry a status header. Why: parallel agents need a claimable, lockable list of who is doing what. Commit messages alone ("R23, R18") don't show which work is open. (refs: docs/workflow.md)
- 2026-11-06: Agent instructions live in `CLAUDE.md` (root and one per package). `AGENTS.md` is a symlink to the root file. Why: one source of truth for every coding agent, and package rules load only when an agent works in that package.
- 2026-11-06: Generated files stay committed. Parallel branches resolve conflicts by regenerating (`tool/regen.sh`), not by merging by hand. Why: the app and web build need the assets without running generators, and CI already checks that generated output matches its sources.
- 2026-09-19: Prefer composition and small value objects over inheritance. Add an abstract interface only where implementations actually vary. (refs: plans/ABSTRACTION_REFACTORING_PLAN.md)
- 2026-09-19: A drafted explanation corpus needs human review. An LLM may draft prose but must not choose the authoritative legal source or its historical version. (refs: plans/QUESTION_EXPLANATIONS_PLAN.md)
