# pm_questions_bank: agent notes

See [README.md](README.md) for the source format. Rules agents most often get
wrong:

- **Edit the right copy**: the canonical source is `assets/pm_260326/pm1*.txt`.
  The repo-root `pm_260326/` folder is an archive that nothing reads. Never
  edit it to fix a question.
- **Never edit `assets/pm_260326_json/`**: run
  `fvm dart run tools/compile_question_assets.dart` from this folder, then
  review the JSON diff. It should touch only the questions you changed.
- **Positional answers**: if an answer refers to its position ("todas las
  anteriores", "A y B son correctas"), add the question code to
  `assets/pm_260326/non_shuffleable.txt`. Treat a compiler warning about an
  unmatched override code as an error.
- **Question codes are stored user data**: renaming or reusing a code changes
  what saved progress points to. That needs a compatibility decision (ADR 0004).
- **Content correctness**: this repo checks structure, not legal accuracy.
  Never change an answer key without a cited source in the PR description.
- **Parsing and validation live in `pm_questions`** (ADR 0005). This package
  holds only the corpus, the compiler and the Flutter asset loader.

Check: `fvm exec ../../tool/verify.sh --only packages/pm_questions_bank`.
