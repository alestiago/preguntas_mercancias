#!/usr/bin/env bash
#
# PostToolUse hook (Edit/Write/MultiEdit): formats an edited Dart file so
# formatting never fails the quality gate. Never blocks: always exits 0.

set -uo pipefail

input="$(cat)"
if command -v jq >/dev/null 2>&1; then
  file="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')"
else
  file="$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path") or "")')"
fi

case "$file" in
  *.g.dart | "") exit 0 ;;
  *.dart) ;;
  *) exit 0 ;;
esac
[[ -f "$file" ]] || exit 0

cd "$(dirname "$file")" || exit 0
if command -v fvm >/dev/null 2>&1; then
  fvm dart format "$file" >/dev/null 2>&1 || true
else
  dart format "$file" >/dev/null 2>&1 || true
fi
exit 0
