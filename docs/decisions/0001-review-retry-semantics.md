# ADR 0001: Review retry semantics

- Status: Accepted
- Scope: review practice

## Context

Review practice contains questions that have persisted attempts but have never
been answered correctly. A wrong selection must not make such a question
unanswerable, and session totals must describe actual attempts rather than
distinct questions.

## Decision

After a wrong review answer, the question remains eligible. Navigation may show
the result before moving on, but when that question becomes the active review
target again its session selection is cleared and the controls reopen.

Every submitted selection is one attempt: it updates the session attempt totals
and is persisted once. A correct attempt makes the question ineligible for
review because lifetime progress now records at least one correct attempt.
Review completes only when no eligible question remains.

Ordinary, pending, simulacro, and single-question sessions do not inherit the
review reopening behavior. Their retained selections continue to support
back/forward navigation and summaries.

## Consequences

- A single wrong review question can loop until answered correctly.
- Multi-question review cycles only through questions that still need review.
- Score counters can exceed the number of distinct questions.
- `selectedOptionsByQuestionCode` is a presentation snapshot, not the durable
  attempt ledger.
