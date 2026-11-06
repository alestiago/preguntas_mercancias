# ADR 0002: “Ever correct” lifetime progress

- Status: Accepted
- Scope: catalog progress and practice eligibility

## Context

Persisted progress contains cumulative correct/incorrect attempt counts and the
latest answer result. Home and practice modes need one stable definition of
whether a question is pending, needs review, or is mastered.

## Decision

Lifetime status is based on the complete persisted attempt history:

- no attempt: `unanswered`;
- one or more attempts and zero correct attempts: `needsReview`;
- one or more correct attempts: `mastered`.

Mastery is sticky. A later wrong attempt updates the latest-answer fields and
history, but does not return an ever-correct question to review. Resetting
progress is the operation that removes lifetime status.

The latest result remains useful for session rendering and history, but it does
not define lifetime eligibility.

## Consequences

- Home counts partition the current catalog into unanswered, needs-review, and
  mastered questions.
- Pending mode selects only unanswered questions.
- Review mode selects only attempted questions with no correct attempt.
- UI wording and tests must not equate “last answer was correct” with
  “mastered.”

## Related code

- [`pm_app/lib/src/practice/practice_question_policy.dart`](../../pm_app/lib/src/practice/practice_question_policy.dart)
- [`packages/pm_persistence/lib/src/models/question_progress.dart`](../../packages/pm_persistence/lib/src/models/question_progress.dart)
- [`packages/pm_persistence/lib/src/stores/drift_question_progress_store.dart`](../../packages/pm_persistence/lib/src/stores/drift_question_progress_store.dart)
- [`pm_app/lib/src/home/`](../../pm_app/lib/src/home/)
