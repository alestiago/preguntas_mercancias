# pm_questions: agent notes

See [README.md](README.md). Rules agents most often get wrong:

- **Pure Dart only** ([ADR 0005](../../docs/decisions/0005-question-domain-boundaries.md)).
  Never import `package:flutter`. Use `dart`, not `flutter`, to resolve, analyze
  and test this package.
- **Two entry points**: `pm_questions.dart` (domain) for app and persistence
  code, and `question_ingestion.dart` (codec and parser) only at trusted input
  boundaries and in the compiler.
- **Validation split**: JSON shape validation lives in `QuestionJsonCodec` and
  throws `FormatException`. The `Question` constructor enforces only core
  invariants and throws `ArgumentError`. Don't move one into the other.
- **Wide impact**: every other package depends on this one. `verify.sh --changed`
  re-checks all of them.

Check: `fvm exec ../../tool/verify.sh --only packages/pm_questions`.
