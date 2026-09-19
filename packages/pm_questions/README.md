# pm_questions

Pure Dart question domain and ingestion APIs shared by the Flutter app,
persistence adapters, Flutter asset loader, and question compiler.

This package intentionally has no Flutter dependency.

## Entry points

| Import | API |
| --- | --- |
| `package:pm_questions/pm_questions.dart` | `Question`, `QuestionAnswer`, and `QuestionOption` |
| `package:pm_questions/question_ingestion.dart` | JSON codec and source-text parser, plus the domain API |

Use the domain entry point in application and persistence code. Import the
ingestion entry point only at a trusted input boundary or in the compiler.

## Validation boundary

`QuestionJsonCodec.decode` performs schema validation and reports malformed
external data as `FormatException`. `QuestionTxtParser` maps source records
through that same codec.

Direct `Question` construction enforces the smaller set of invariants required
by every in-memory question: non-blank fields, four unique A–D answers,
non-blank answer text, and a correct option present in the answers. Invalid
direct construction throws `ArgumentError`.

This keeps elaborate JSON-shape validation at ingestion without allowing
malformed direct instances to fail later during answer lookup or presentation.

## Verify with Dart only

```sh
dart pub get --enforce-lockfile
dart analyze
dart test --test-randomize-ordering-seed=random
```

The repository-level verification script runs these commands independently of
Flutter package analysis and tests.
