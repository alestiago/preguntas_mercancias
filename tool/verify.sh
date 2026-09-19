#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
readonly dart_packages=(
  "packages/pm_questions"
)
readonly flutter_packages=(
  "pm_app"
  "packages/pm_questions_bank"
  "packages/pm_persistence"
)

for package in "${dart_packages[@]}"; do
  echo "==> Resolving locked dependencies for $package"
  (
    cd "$repository_root/$package"
    dart pub get --enforce-lockfile
  )
done

for package in "${flutter_packages[@]}"; do
  echo "==> Resolving locked dependencies for $package"
  (
    cd "$repository_root/$package"
    flutter pub get --enforce-lockfile
  )
done

echo "==> Checking Dart formatting"
tracked_dart_files=()
while IFS= read -r file; do
  if [[ -f "$repository_root/$file" ]]; then
    tracked_dart_files+=("$repository_root/$file")
  fi
done < <(
  git -C "$repository_root" ls-files \
    --cached --others --exclude-standard -- '*.dart'
)
dart format --output=none --set-exit-if-changed "${tracked_dart_files[@]}"

echo "==> Regenerating checked-in files"
(
  cd "$repository_root/packages/pm_persistence"
  dart run build_runner build
)
(
  cd "$repository_root/pm_app"
  flutter gen-l10n
)
(
  cd "$repository_root/packages/pm_questions_bank"
  dart run tools/compile_question_assets.dart
)

readonly generated_paths=(
  "packages/pm_persistence/lib/src/database/pm_persistence_database.g.dart"
  "pm_app/lib/l10n/app_localizations.dart"
  "pm_app/lib/l10n/app_localizations_es.dart"
  "packages/pm_questions_bank/assets/pm_260326_json"
)
generated_diff="$(
  git -C "$repository_root" diff --name-status -- "${generated_paths[@]}"
)"
generated_untracked="$(
  git -C "$repository_root" ls-files --others --exclude-standard -- \
    "${generated_paths[@]}"
)"
if [[ -n "$generated_diff" || -n "$generated_untracked" ]]; then
  echo "Generated output differs from the staged snapshot. Regenerate and stage these changes:"
  if [[ -n "$generated_diff" ]]; then
    echo "$generated_diff"
  fi
  if [[ -n "$generated_untracked" ]]; then
    echo "$generated_untracked"
  fi
  git -C "$repository_root" --no-pager diff -- "${generated_paths[@]}"
  exit 1
fi

for package in "${dart_packages[@]}"; do
  echo "==> Analyzing $package"
  (
    cd "$repository_root/$package"
    dart analyze
  )

  echo "==> Testing $package"
  (
    cd "$repository_root/$package"
    dart test --test-randomize-ordering-seed=random
  )
done

for package in "${flutter_packages[@]}"; do
  echo "==> Analyzing $package"
  (
    cd "$repository_root/$package"
    flutter analyze --no-pub
  )

  echo "==> Testing $package"
  (
    cd "$repository_root/$package"
    flutter test --no-pub --test-randomize-ordering-seed=random
  )
done
