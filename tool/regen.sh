#!/usr/bin/env bash
#
# Regenerates checked-in generated code.
#
#   fvm exec ./tool/regen.sh                 # every generator
#   fvm exec ./tool/regen.sh pm_app          # only the generators owned by pm_app
#
# Run it after editing a generator source, or to resolve a merge conflict in a
# generated file: accept either side of the conflict, then regenerate. Packages
# must already be resolved (run ./tool/bootstrap.sh in a fresh checkout).

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
# shellcheck source=tool/packages.sh
source "$repository_root/tool/packages.sh"

selected=""
if [[ $# -eq 0 ]]; then
  selected="${PM_ALL_PACKAGES[*]}"
else
  for argument in "$@"; do
    selected="$selected $(pm_normalize_package "$argument")"
  done
fi

if pm_list_contains "packages/pm_persistence" "$selected"; then
  echo "==> Generating Drift code (packages/pm_persistence)"
  (
    cd "$repository_root/packages/pm_persistence"
    dart run build_runner build
  )
fi

if pm_list_contains "pm_app" "$selected"; then
  echo "==> Generating localizations (pm_app)"
  (
    cd "$repository_root/pm_app"
    flutter gen-l10n
  )
fi

if pm_list_contains "packages/pm_questions_bank" "$selected"; then
  echo "==> Compiling question assets (packages/pm_questions_bank)"
  (
    cd "$repository_root/packages/pm_questions_bank"
    dart run tools/compile_question_assets.dart
  )
fi
