# pm_persistence

Persistence adapters for Preguntas Mercancías. The package stores question
attempts and aggregate progress in Drift, and the answer-shuffle preference in
shared preferences. It depends on the pure `pm_questions` domain for canonical
option identity and does not depend on Flutter asset loading.

## Responsibilities

| API | Production implementation | Data |
| --- | --- | --- |
| `QuestionProgressStore` | `DriftQuestionProgressStore` | Every answer attempt, per-question aggregate counts, last selection, and timestamps |
| `SettingsStore` | `SharedPreferencesSettingsStore` | Whether answer choices are shuffled |

`QuestionProgressStore.recordAnswer` writes the attempt and its aggregate
progress in one database transaction. Clearing progress removes both tables.
The settings store is independent, so resetting question progress does not
reset the shuffle preference. When no preference has been saved,
`SharedPreferencesSettingsStore` defaults answer shuffling to enabled.

## Store contracts

The public interfaces in `lib/src/stores` are the source of truth. In summary:

- Snapshot and settings watch streams emit the current value after each
  subscription, then later observed values.
- Answer-history reads and emissions are bounded by a caller-supplied positive
  limit and report whether an older prefix exists. They are newest first;
  Drift breaks equal timestamps by newest insertion first. Increasing the
  limit grows the prefix without offset drift when new attempts arrive, but
  callers must not use tie order as record identity.
- Drift watchers observe writes made by another store backed by the same
  database. The shared-preferences watcher only reports successful writes made
  through its own store instance.
- Future failures are thrown to the caller; watch failures are emitted as
  stream errors. Adapters do not translate storage failures into user-facing
  messages.
- The component that creates a store owns it and must call `close()` exactly
  once after all consumers are finished. Injected feature BLoCs are consumers,
  not owners. Production ownership sits with `AppDependenciesOwner`.

Tests and fakes implementing these interfaces must preserve these observable
contracts without reproducing the entire persistence implementation.

The primary `pm_persistence.dart` entry point deliberately does not export
`PmPersistenceDatabase` or generated Drift table/row types. Those are adapter
implementation details; application features consume stores and persistence
models.

## Drift generation

The table declarations live in
`lib/src/database/pm_persistence_database.dart`; the sibling `.g.dart` file is
generated and checked in. After changing a table or database declaration, run
from this package directory:

```sh
fvm dart run build_runner build
```

Do not edit generated Drift code by hand.

The current schema version is 1. Every schema change must follow the accepted
[persistence versioning decision](../../docs/decisions/0004-persistence-versioning.md):
increment the schema version, provide a forward migration, and test upgrades
from every supported prior version. Silently deleting user progress is not a
migration strategy.

## Web runtime

`PmPersistenceDatabase.defaults()` expects `sqlite3.wasm` and
`drift_worker.js` at the web application root. The app currently supplies them
under `pm_app/web`; keep deployment output compatible with those URIs.

## Test and analyze

```sh
fvm flutter analyze --no-pub
fvm flutter test --no-pub --test-randomize-ordering-seed=random
```

Run `fvm exec ./tool/verify.sh` from the repository root before submitting a
change.
