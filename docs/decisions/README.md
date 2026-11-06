# Architecture decisions

These records capture product and data rules that should not be inferred from a
single widget or BLoC branch. Update the relevant record when intentionally
changing one of these decisions, and include the corresponding behavior tests
in the same change.

| ADR | Status | Decision |
| --- | --- | --- |
| [0001](0001-review-retry-semantics.md) | Accepted | Review retries remain open until a question is answered correctly |
| [0002](0002-ever-correct-progress.md) | Accepted | A question is mastered after any persisted correct attempt |
| [0003](0003-session-completion.md) | Accepted | Completion depends on the explicit session mode |
| [0004](0004-persistence-versioning.md) | Accepted | Persisted data evolves through tested forward migrations |
| [0005](0005-question-domain-boundaries.md) | Accepted | Pure question APIs are isolated from Flutter asset and persistence adapters |

## Writing a new ADR

1. Copy [TEMPLATE.md](TEMPLATE.md) to `NNNN-kebab-title.md` with the next free number.
2. Start as `Proposed`. Change it to `Accepted` in the change that implements it.
3. Fill in **Related code** so anyone editing those files can find the decision.
4. Add a row to the table above.

To reverse a decision, write a new ADR and mark the old one
`Superseded by [ADR NNNN](...)`. Never delete history.

## Smaller decisions

For choices that don't govern product behavior or stored data (a convention, a
rejected library, the reason for a pattern), add a dated line to
[log.md](log.md) instead.

## When an ADR is needed

- The change alters what a user sees as correct behavior (completion, scoring,
  eligibility, progress).
- The change affects stored data or how stored question codes are interpreted.
- The change moves a package boundary or public API.
- A reviewer would otherwise ask "why is it like this?" and the answer isn't in
  the code.
