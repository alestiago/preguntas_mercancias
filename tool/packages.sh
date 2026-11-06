#!/usr/bin/env bash
# Shared package metadata for the scripts in tool/. Source it; don't execute it.
# Keep it compatible with bash 3.2 (the macOS default): no associative arrays.

# Every package, ordered so that dependencies come before their dependents.
readonly PM_ALL_PACKAGES=(
  "packages/pm_questions"
  "packages/pm_questions_bank"
  "packages/pm_persistence"
  "pm_app"
  "widgetbook"
)

# Packages resolved, analyzed and tested with plain Dart instead of Flutter.
pm_is_dart_package() {
  [[ "$1" == "packages/pm_questions" ]]
}

# Packages that depend on the given one through path dependencies, directly or
# indirectly. Keep this in sync with the pubspec.yaml files.
pm_dependents() {
  case "$1" in
    packages/pm_questions)
      echo "packages/pm_questions_bank packages/pm_persistence pm_app widgetbook" ;;
    packages/pm_questions_bank | packages/pm_persistence)
      echo "pm_app widgetbook" ;;
    pm_app)
      echo "widgetbook" ;;
    *)
      echo "" ;;
  esac
}

# Checked-in generated output owned by the given package (repo-relative).
pm_generated_paths() {
  case "$1" in
    packages/pm_persistence)
      echo "packages/pm_persistence/lib/src/database/pm_persistence_database.g.dart" ;;
    pm_app)
      echo "pm_app/lib/l10n/app_localizations.dart pm_app/lib/l10n/app_localizations_es.dart" ;;
    packages/pm_questions_bank)
      echo "packages/pm_questions_bank/assets/pm_260326_json" ;;
    *)
      echo "" ;;
  esac
}

# Prints the canonical package name for user input such as "./pm_app/" or
# "pm_persistence", or fails if it isn't a known package.
pm_normalize_package() {
  local input="${1#./}"
  input="${input%/}"
  local package
  for package in "${PM_ALL_PACKAGES[@]}"; do
    if [[ "$input" == "$package" || "packages/$input" == "$package" ]]; then
      echo "$package"
      return 0
    fi
  done
  echo "Unknown package: $1 (expected one of: ${PM_ALL_PACKAGES[*]})" >&2
  return 1
}

# True if the space-separated list $2 contains $1.
pm_list_contains() {
  case " $2 " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

# Expands a space-separated package list with all dependents and prints it in
# canonical order.
pm_expand_with_dependents() {
  local selected="$1"
  local package dependent
  for package in $1; do
    for dependent in $(pm_dependents "$package"); do
      if ! pm_list_contains "$dependent" "$selected"; then
        selected="$selected $dependent"
      fi
    done
  done
  pm_canonical_order "$selected"
}

# Prints the packages of a space-separated list in canonical order.
pm_canonical_order() {
  local ordered="" package
  for package in "${PM_ALL_PACKAGES[@]}"; do
    if pm_list_contains "$package" "$1"; then
      ordered="${ordered:+$ordered }$package"
    fi
  done
  echo "$ordered"
}
