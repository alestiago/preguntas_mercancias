# ADR 0003: Session completion

- Status: Accepted
- Scope: practice session navigation and summaries

## Context

Different practice modes have different terminal behavior. Encoding completion
as a generic “last question” check makes filtered sessions finish too early and
makes skipped simulacro questions ambiguous.

## Decision

Completion is selected by `PracticeSessionConfig`:

- Standard practice restarts the current set after the terminal question is
  answered. Earlier questions may be navigated without answering.
- Simulacro and single-question sessions finish at the terminal question after
  it is answered. Earlier skipped questions are allowed and represented as
  unanswered in the summary.
- Review finishes when no question remains eligible. Incorrect review answers
  remain eligible and therefore keep the session open.
- Pending practice finishes when no pending question remains and the pending
  source is exhausted. While a refill is loading or recoverable failure is
  unresolved, completion stays unavailable.

An answer write blocks navigation and exit. Leaving an answered simulacro
requires confirmation; leaving an unanswered one does not.

## Consequences

- Completion UI derives from state policy instead of duplicating mode checks.
- Simulacro scores distinguish unanswered questions from incorrect attempts.
- Filtered sessions can wrap through their source list without implying
  completion.
- New session modes must choose an explicit completion policy and add focused
  tests.
