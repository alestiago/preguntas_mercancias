#!/usr/bin/env bash
#
# Repository quality gate: resolve locked dependencies, check formatting,
# regenerate checked-in files and fail on drift, analyze, and run tests in
# random order.
#
#   fvm exec ./tool/verify.sh                       # every package (what CI runs)
#   fvm exec ./tool/verify.sh --only pm_app         # chosen packages (repeatable)
#   fvm exec ./tool/verify.sh --changed             # packages changed vs. base, plus dependents
#   fvm exec ./tool/verify.sh --changed --base main # choose the base ref (default: origin/main)
#   ./tool/verify.sh --changed --dry-run            # only print the selected packages
#
# --changed covers commits since the merge base, staged and unstaged edits, and
# untracked files. Changes to tool/, .github/, .fvmrc or the root
# analysis_options.yaml select every package. Docs-only changes select none.

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
# shellcheck source=tool/packages.sh
source "$repository_root/tool/packages.sh"

usage() {
  sed -n '3,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

mode="all"
only=""
dry_run=false
base_ref="${VERIFY_BASE:-origin/main}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --only)
      [[ $# -ge 2 ]] || { echo "--only needs a package" >&2; exit 2; }
      mode="only"
      only="$only $(pm_normalize_package "$2")"
      shift 2 ;;
    --changed)
      mode="changed"
      shift ;;
    --dry-run)
      dry_run=true
      shift ;;
    --base)
      [[ $# -ge 2 ]] || { echo "--base needs a ref" >&2; exit 2; }
      base_ref="$2"
      shift 2 ;;
    -h | --help)
      usage
      exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2 ;;
  esac
done

changed_files() {
  local merge_base
  if ! merge_base="$(git -C "$repository_root" merge-base "$base_ref" HEAD 2>/dev/null)"; then
    echo "Cannot find merge base with '$base_ref'; pass --base <ref>." >&2
    exit 2
  fi
  {
    git -C "$repository_root" diff --name-only "$merge_base"
    git -C "$repository_root" ls-files --others --exclude-standard
  } | sort -u
}

case "$mode" in
  all)
    selected="${PM_ALL_PACKAGES[*]}" ;;
  only)
    selected="$(pm_canonical_order "$only")" ;;
  changed)
    touched=""
    while IFS= read -r file; do
      [[ -n "$file" ]] || continue
      case "$file" in
        tool/* | .github/* | .fvmrc | analysis_options.yaml)
          touched="${PM_ALL_PACKAGES[*]}"
          break ;;
      esac
      for package in "${PM_ALL_PACKAGES[@]}"; do
        if [[ "$file" == "$package/"* ]] && ! pm_list_contains "$package" "$touched"; then
          touched="$touched $package"
        fi
      done
    done < <(changed_files)
    selected="$(pm_expand_with_dependents "$touched")" ;;
esac

if [[ -z "${selected// /}" ]]; then
  echo "No package changes relative to $base_ref; nothing to verify."
  exit 0
fi

if [[ "$dry_run" == true ]]; then
  echo "$selected"
  exit 0
fi

echo "==> Verifying: $selected"

for package in $selected; do
  echo "==> Resolving locked dependencies for $package"
  (
    cd "$repository_root/$package"
    if pm_is_dart_package "$package"; then
      dart pub get --enforce-lockfile
    else
      flutter pub get --enforce-lockfile
    fi
  )
done

echo "==> Checking Dart formatting"
format_pathspecs=()
if [[ "$mode" == "all" ]]; then
  format_pathspecs=('*.dart')
else
  for package in $selected; do
    format_pathspecs+=("$package/*.dart")
  done
fi
tracked_dart_files=()
while IFS= read -r file; do
  if [[ -f "$repository_root/$file" ]]; then
    tracked_dart_files+=("$repository_root/$file")
  fi
done < <(
  git -C "$repository_root" ls-files \
    --cached --others --exclude-standard -- "${format_pathspecs[@]}"
)
if [[ ${#tracked_dart_files[@]} -gt 0 ]]; then
  dart format --output=none --set-exit-if-changed "${tracked_dart_files[@]}"
fi

echo "==> Regenerating checked-in files"
# shellcheck disable=SC2086
"$repository_root/tool/regen.sh" $selected

generated_paths=()
for package in $selected; do
  for path in $(pm_generated_paths "$package"); do
    generated_paths+=("$path")
  done
done
if [[ ${#generated_paths[@]} -gt 0 ]]; then
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
fi

for package in $selected; do
  echo "==> Analyzing $package"
  (
    cd "$repository_root/$package"
    if pm_is_dart_package "$package"; then
      dart analyze
    else
      flutter analyze --no-pub
    fi
  )

  echo "==> Testing $package"
  (
    cd "$repository_root/$package"
    if pm_is_dart_package "$package"; then
      dart test --test-randomize-ordering-seed=random
    else
      flutter test --no-pub --test-randomize-ordering-seed=random
    fi
  )
done
