#!/usr/bin/env bash
# my-vibe PostToolUse(Write|Edit) check — if a .env file was just written and is
# NOT covered by .gitignore, surface a non-blocking warning so the user can fix it
# before it ever gets staged. Never blocks; only informs.
set -euo pipefail

input="$(cat)"

if command -v jq >/dev/null 2>&1; then
  path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)"
  cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
else
  path="$(printf '%s' "$input" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"//; s/"$//' || true)"
  cwd=""
fi

[ -z "${path:-}" ] && exit 0

base="$(basename "$path")"
case "$base" in
  .env|.env.local|.env.*.local)
    root="${cwd:-$(pwd)}"
    gi="$root/.gitignore"
    if [ ! -f "$gi" ] || ! grep -Eq '(^|/)\.env($|[[:space:]]|/|\*)' "$gi"; then
      echo "⚠ my-vibe: $base 를 작성했지만 .gitignore가 .env를 무시하지 않습니다. 비밀 유출 방지를 위해 .gitignore에 '.env' 항목을 추가하세요." >&2
    fi
    ;;
esac

exit 0
