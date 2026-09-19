# pm_questions_bank

Flutter adapter package containing the versioned Preguntas Mercancías corpus,
its compiled assets, the compilation tool, and the `AssetBundle` loader.

Canonical question models and ingestion APIs live in the pure Dart
[`pm_questions`](../pm_questions/) package. Application and persistence code
should depend on that package directly rather than importing this asset adapter.

## Public API

`package:pm_questions_bank/pm_questions_bank.dart` exports only
`QuestionBankLoader`. The loader reads validated `Question` values from
Flutter assets through `rootBundle` or an injected `AssetBundle`.

Unknown section codes throw `ArgumentError`; malformed compiled assets throw
`FormatException`. `QuestionBankLoader.sections` is the current maintained
section list.

## Current edition and source ownership

`pm_260326` is the current bank-edition identifier. Treat the label as an
opaque corpus version; changing editions is a deliberate data update.

| Path | Role |
| --- | --- |
| `assets/pm_260326/pm1A.txt` … `pm1H.txt` | Canonical editable source for sections 1A–1H |
| `assets/pm_260326/non_shuffleable.txt` | Canonical positional-answer overrides |
| `assets/pm_260326_json/*.json` | Generated, checked-in runtime assets |
| `tools/compile_question_assets.dart` | Deterministic source-to-JSON compiler |

The repository-level `../../pm_260326/` directory is an archival copy of the
upstream text files. The compiler does not read it. Make corrections in this
package's source directory, regenerate, and review the JSON diff. Only update
the root archive when intentionally replacing its archived upstream copy.

## Source format

Each text record begins with `COD:` and uses `PREGUNTA:`, answer labels
`A:` through `D:`, `SOLUCION:`, `NORMA:`, and optional
`REFERENCIA DOCTRINAL:` fields. Unlabelled non-empty lines continue the
preceding field.

Some answer text refers to positions such as “todas las anteriores.” Put one
question code per line in `non_shuffleable.txt` to preserve its source order.
Blank lines and lines beginning with `#` are ignored. Compilation warns when
an override code matches no source question; investigate that warning before
committing generated output.

Parsing and JSON schema validation are implemented by `pm_questions`, keeping
this package focused on corpus and Flutter-asset concerns.

## Compile assets

From this package directory:

```sh
fvm dart run tools/compile_question_assets.dart
```

The command compiles all eight sections into `assets/pm_260326_json`. Do not
edit generated JSON by hand. The root verification command regenerates these
files and fails on drift.

When adding a section, update the source files, compiler list, loader asset map,
pubspec assets if necessary, and tests together.

## Test and analyze

```sh
fvm flutter analyze --no-pub
fvm flutter test --no-pub --test-randomize-ordering-seed=random
```

Run `fvm exec ./tool/verify.sh` from the repository root before submitting a
change.
