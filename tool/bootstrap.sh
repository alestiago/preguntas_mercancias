#!/usr/bin/env bash
#
# Prepares a fresh clone or git worktree for development:
#   - installs the Flutter SDK pinned in .fvmrc (when FVM is available)
#   - resolves every package from its lockfile
#   - enables git rerere for this repository, so a conflict resolved once
#     during a rebase is replayed automatically next time
#
#   ./tool/bootstrap.sh
#
# Safe to rerun.

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
# shellcheck source=tool/packages.sh
source "$repository_root/tool/packages.sh"

if command -v fvm >/dev/null 2>&1; then
  echo "==> Installing the pinned Flutter SDK with FVM"
  (cd "$repository_root" && fvm install)
  dart_cmd=(fvm dart)
  flutter_cmd=(fvm flutter)
else
  echo "==> FVM not found; using the Flutter on PATH ($(command -v flutter || echo 'none'))"
  dart_cmd=(dart)
  flutter_cmd=(flutter)
fi

for package in "${PM_ALL_PACKAGES[@]}"; do
  echo "==> Resolving locked dependencies for $package"
  (
    cd "$repository_root/$package"
    if pm_is_dart_package "$package"; then
      "${dart_cmd[@]}" pub get --enforce-lockfile
    else
      "${flutter_cmd[@]}" pub get --enforce-lockfile
    fi
  )
done

git -C "$repository_root" config rerere.enabled true

cat <<'EOF'

Ready. Useful next steps:
  fvm exec ./tool/verify.sh --changed   # check what you changed
  fvm exec ./tool/verify.sh             # full gate (same as CI)
  gh issue list --label status:ready    # find a task to claim
EOF
