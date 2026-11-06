# pm_persistence: agent notes

See [README.md](README.md) for the store contracts. Rules agents most often get
wrong:

- **Schema changes follow [ADR 0004](../../docs/decisions/0004-persistence-versioning.md)**:
  bump `schemaVersion`, write an explicit forward migration from every
  supported version, keep user data, regenerate, and test both a fresh
  database and upgrades. Never fix a migration problem by recreating the
  database.
- **Generated code**: `lib/src/database/pm_persistence_database.g.dart` is
  produced by `fvm dart run build_runner build`. Never edit it by hand.
- **Public API**: `lib/pm_persistence.dart` must not export the Drift database
  or generated row types. The app uses stores and models only.
- **Contracts are observable behavior**: watch streams emit the current value
  first, history is newest-first and bounded, and `recordAnswer` is one
  transaction. Fakes in `pm_app/test/helpers/` must keep these contracts too.
  Update them when a contract changes.
- **Ownership**: whoever creates a store calls `close()` once.
- **Hotspot**: the schema file conflicts easily across parallel branches.
  Coordinate through the issue before changing it.

Check: `fvm exec ../../tool/verify.sh --only packages/pm_persistence` (`--changed`
also picks up `pm_app` and `widgetbook`, which depend on this package).
