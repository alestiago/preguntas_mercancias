# Backlog index

Status of every R (refactoring review) and A (abstraction plan) item. Use this
file only until open items are filed as GitHub Issues. After that, the
**Issue** column links them and the issue is the source of truth.

Status was inferred on 2026-11-06 from commit messages and the code:

- **done**: a commit message names the item.
- **likely done**: there's strong evidence in the code but no commit names the item. Confirm before closing.
- **open**: not started, or evidence shows it's still pending.

## Refactoring review: [docs/REFACTORING_REVIEW.md](../docs/REFACTORING_REVIEW.md)

| ID | Item | Status | Evidence | Issue |
| --- | --- | --- | --- | --- |
| R01 | Separate review attempts from saved selections | done | 1480841 | |
| R02 | BLoC concurrency and stale-result rules | done | 0f1153b | |
| R03 | Model saving and failure recovery explicitly | **open** | No commit. Overlaps with A09. | |
| R04 | Typed session configuration | done | 7943bf3 | |
| R05 | Eligibility and selection policies | done | aa9c6f3 | |
| R06 | Pending-batch result contract | done | 71a376a | |
| R07 | Navigation, completion and exit policies | done | 77a1b6c | |
| R08 | One session clock and formatter | done | 6fd6951 | |
| R09 | History and settings behind feature state | done | 0da684d | |
| R10 | Consistent initialization and observation | done | 4544eab, 71a376a | |
| R11 | Dependency creation and ownership | done | 1cc7ee5 | |
| R12 | Split large page libraries | done | 644bd7e | |
| R13 | Shared loading, error and empty states | done | 6a59fcc | |
| R14 | Theme tokens and answer-status presentation | done | 6a59fcc | |
| R15 | Immutable state and equality | done | f34e548 | |
| R16 | Answer identity vs. shuffled presentation | done | 0da684d | |
| R17 | Reusable catalog and section metadata | likely done | `QuestionCatalog` (62d4fa5), bank manifest (0556147) | |
| R18 | Pure domain APIs | done | cf7dda4, ADR 0005 | |
| R19 | Reproducible asset compilation | likely done | `verify.sh` regenerates and fails on drift | |
| R20 | Persistence invariants and migration workflow | likely done | ADR 0004, store contracts in package README | |
| R21 | Test organization and async assertions | done | bd524ec | |
| R22 | Shared quality gate | likely done | `tool/verify.sh`, `.github/workflows/verify.yml` | |
| R23 | Project documentation | done | cf7dda4 | |
| R24 | Localization, semantics, responsive cleanup | done | 53acb66 | |
| R25 | Central app metadata and build configuration | **open** | `applicationId` is still `com.example.pm_app` | |
| R26 | Bound large-history and long-session work | likely done | [docs/performance/R26.md](../docs/performance/R26.md) | |
| R27 | Tracked build caches and ignore rules | done | 1348e53 | |

## Abstraction plan: [ABSTRACTION_REFACTORING_PLAN.md](ABSTRACTION_REFACTORING_PLAN.md)

| ID | Item | Status | Evidence | Issue |
| --- | --- | --- | --- | --- |
| A01 | Immutable `QuestionCatalog` | likely done | 62d4fa5 "catalog" | |
| A02 | One bank manifest | likely done | 0556147 "bank manifest" | |
| A03 | `PracticeLaunch` and session question source | done | 42dfcf2 | |
| A04 | Session answers and pure transitions | done | 8996e08 | |
| A05 | Mode capabilities and pending options | done | 8996e08 | |
| A06 | Event-owned stream subscriptions | done | 2b3f26f | |
| A07 | Generated immutable state/data classes (trial) | **open** | Plan says to wait until session shapes settle | |
| A08 | Observable persisted preference | **open** | Conditional (P3) | |
| A09 | Typed answer-commit outcome | **open** | Behavior change. Overlaps with R03. | |
| A10 | Shared question-status badge | **open** | Not confirmed. Check `session_question_status_badge.dart` usage. | |

## Other plans

| Item | Status | Issue |
| --- | --- | --- |
| Question explanations corpus ([plan](QUESTION_EXPLANATIONS_PLAN.md)) | draft: needs a go/no-go | |
