#!/usr/bin/env bash
# my-vibe PreToolUse(Bash) guard — block staging/committing secret files.
# Reads hook JSON on stdin; denies the tool call if the Bash command tries to
# `git add` / `git commit` a .env or other obvious secret file.
# Output format: PreToolUse permissionDecision (deny) — see Claude Code hooks docs.
set -euo pipefail

input="$(cat)"

# Extract the bash command (jq if available, else grep fallback).
if command -v jq >/dev/null 2>&1; then
  cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
else
  cmd="$(printf '%s' "$input" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"command"[[:space:]]*:[[:space:]]*"//; s/"$//' || true)"
fi

[ -z "${cmd:-}" ] && exit 0

# Only inspect git add / git commit -a style commands that could stage secrets.
if printf '%s' "$cmd" | grep -Eiq 'git[[:space:]]+(add|commit)'; then
  # Deny if a secret-looking path is explicitly referenced.
  if printf '%s' "$cmd" | grep -Eiq '(^|[[:space:]/])\.env([[:space:].]|$)|\.env\.local|\.env\.[^[:space:]]*\.local|(^|[[:space:]/])(credentials|secrets?)\.(json|ya?ml|env)|id_rsa|\.pem([[:space:]]|$)'; then
    reason="my-vibe guard: .env/비밀 파일을 git에 staging/commit하려는 시도를 차단했습니다. .gitignore에 .env가 있는지 확인하고, 비밀은 1Password/Vault로 관리하세요."
    if command -v jq >/dev/null 2>&1; then
      jq -nc --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
    else
      printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' "$reason"
    fi
    exit 0
  fi
fi

exit 0
