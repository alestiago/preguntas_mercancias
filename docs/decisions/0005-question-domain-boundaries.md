# ADR 0005: Question-domain package boundaries

- Status: Accepted
- Scope: question domain, ingestion, assets, and persistence APIs

## Context

Question models and the source parser are used by application state,
persistence records, the Flutter asset loader, and a command-line compiler.
Keeping them in the asset package forced pure Dart tooling and downstream
domain imports to resolve Flutter services. The same package barrel also
exposed models, parsing, and asset loading as one undifferentiated API.

## Decision

The pure Dart `pm_questions` package owns canonical question models and the
two ingestion adapters: `QuestionJsonCodec` and `QuestionTxtParser`.
`pm_questions_bank` owns the versioned source corpus, compilation tool,
compiled Flutter assets, and `QuestionBankLoader`.

Consumers import the narrowest entry point:

- domain/application/persistence code uses
  `package:pm_questions/pm_questions.dart`;
- trusted ingestion and compiler code uses
  `package:pm_questions/question_ingestion.dart`;
- Flutter composition that loads bundled assets uses
  `package:pm_questions_bank/pm_questions_bank.dart`.

JSON schema validation stays in the ingestion codec. Direct `Question`
construction enforces only the invariants every in-memory consumer requires.
Practice-session results remain app-owned as `PracticeSummary`; they are not
part of the reusable question catalog.

The primary persistence barrel exposes store contracts, adapters, and
persistence models, but not the generated Drift database API.

## Consequences

- The question domain and its tests run with Dart alone.
- Flutter asset services cannot leak through a domain import.
- Persistence depends on canonical option identity without depending on the
  Flutter question-bank package.
- New serialization formats belong at an ingestion boundary rather than as
  constructors on domain entities.
- A future non-Flutter catalog adapter can depend on `pm_questions` without a
  second domain-package split.
