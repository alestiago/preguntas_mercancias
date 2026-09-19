# Architecture decisions

These records capture product and data rules that should not be inferred from a
single widget or BLoC branch. Update the relevant record when intentionally
changing one of these decisions, and include the corresponding behavior tests
in the same change.

| ADR | Decision |
| --- | --- |
| [0001](0001-review-retry-semantics.md) | Review retries remain open until a question is answered correctly |
| [0002](0002-ever-correct-progress.md) | A question is mastered after any persisted correct attempt |
| [0003](0003-session-completion.md) | Completion depends on the explicit session mode |
| [0004](0004-persistence-versioning.md) | Persisted data evolves through tested forward migrations |
| [0005](0005-question-domain-boundaries.md) | Pure question APIs are isolated from Flutter asset and persistence adapters |
