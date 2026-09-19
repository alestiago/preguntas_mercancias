# ADR 0004: Persistence versioning

- Status: Accepted
- Scope: Drift database schema

## Context

Question attempts and aggregate progress are user data. Drift generates the
database implementation, but generated code alone does not define how an
installed database moves between schema versions.

## Decision

Schema version 1 is the baseline. Every released schema change must:

1. increment `PmPersistenceDatabase.schemaVersion`;
2. define an explicit forward migration from every supported prior version;
3. preserve attempts, aggregate counts, timestamps, and settings unless the
   product change explicitly supersedes them;
4. regenerate `pm_persistence_database.g.dart`;
5. test a fresh database and upgrades from supported prior schemas.

Migrations must be deterministic and transactional where Drift permits.
Destructive recreation is allowed only for disposable developer/test databases
or after an explicit product decision that documents the user-data loss. It is
not the default response to a migration problem.

The question-bank edition is independent of the database schema version.
Changes that reinterpret stored question codes require a documented mapping or
compatibility decision in addition to a schema migration.

## Consequences

- Checked-in generated code changes travel with schema declarations and
  migration tests.
- Application code may rely on forward upgrades rather than silently clearing
  progress.
- A schema proposal is incomplete until its migration and rollback/recovery
  implications have been reviewed.
