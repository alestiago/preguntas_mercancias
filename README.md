# preguntas_mercancias

## Verification

The repository uses Flutter 3.47.4, pinned in `.fvmrc`. Run the same quality
gate used by CI from the repository root:

```sh
./tool/verify.sh
```

The command resolves each lockfile, checks formatting, regenerates and checks
the Drift database, Flutter localizations, and compiled question assets, then
runs analysis and tests for the app and both local packages.
