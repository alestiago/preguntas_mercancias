# Plans

Design proposals for non-trivial work: what to build, why, and in what order.
Plans are **not** the task tracker. Who is doing what lives in GitHub Issues,
and [backlog.md](backlog.md) indexes the R/A items until each has an issue.

## Lifecycle

Every plan starts with a header:

```yaml
---
status: draft | active | done | abandoned
updated: YYYY-MM-DD
issue: "#N", or a note
---
```

| Status | Meaning |
| --- | --- |
| `draft` | Proposal under discussion. Don't implement it yet. |
| `active` | Approved. Items are being turned into issues and implemented. |
| `done` | Implemented. Move the file to `archive/`. |
| `abandoned` | Not pursued. Say why in one line under the header, then move it to `archive/`. |

Rules:

- Update `updated:` whenever the plan's content or status changes.
- When a plan produces a lasting product or architecture rule, record it as an
  ADR or a decision-log entry in `docs/decisions/`. A plan is not where future
  agents look for current rules.
- Keep item IDs (R01, A07, …) stable, and use them in issue titles and commits.

## Current plans

| Plan | Status |
| --- | --- |
| [ABSTRACTION_REFACTORING_PLAN.md](ABSTRACTION_REFACTORING_PLAN.md) | active |
| [QUESTION_EXPLANATIONS_PLAN.md](QUESTION_EXPLANATIONS_PLAN.md) | draft |
| [archive/WIDGETBOOK_PLAN.md](archive/WIDGETBOOK_PLAN.md) | done |
| [../docs/REFACTORING_REVIEW.md](../docs/REFACTORING_REVIEW.md) (R01–R27) | mostly done; see backlog |
