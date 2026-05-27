#!/usr/bin/env bash
# my-vibe plugin installer
# Usage:
#   ./install.sh              # symlink (default)
#   ./install.sh --copy       # copy files instead
#   ./install.sh --prefix DIR # custom skills dir (default ~/.claude/skills)
#   ./install.sh --uninstall  # remove installed skills
#   ./install.sh --dry-run    # show what would happen
set -euo pipefail

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="symlink"
PREFIX="${HOME}/.claude/skills"
DRY=0
DO_UNINSTALL=0

log()  { printf "\033[1;34m[my-vibe]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[my-vibe]\033[0m %s\n" "$*" >&2; }
err()  { printf "\033[1;31m[my-vibe]\033[0m %s\n" "$*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --copy)       MODE="copy"; shift ;;
    --symlink)    MODE="symlink"; shift ;;
    --prefix)     PREFIX="$2"; shift 2 ;;
    --uninstall)  DO_UNINSTALL=1; shift ;;
    --dry-run)    DRY=1; shift ;;
    -h|--help)
      sed -n '2,9p' "$0"; exit 0 ;;
    *)
      err "Unknown arg: $1"; exit 2 ;;
  esac
done

[[ -d "$PKG_DIR/skills" ]] || { err "Missing skills/ in $PKG_DIR"; exit 1; }

run() {
  if [[ "$DRY" == "1" ]]; then echo "DRY: $*"; else "$@"; fi
}

skill_names() {
  # 10 vc-* directories + INDEX.md
  ( cd "$PKG_DIR/skills" && find . -maxdepth 1 -mindepth 1 \( -type d -name 'vc-*' -o -name 'INDEX.md' \) -printf '%f\n' )
}

if [[ "$DO_UNINSTALL" == "1" ]]; then
  log "Uninstalling my-vibe skills from $PREFIX"
  for n in $(skill_names); do
    target="$PREFIX/$n"
    if [[ -L "$target" || -e "$target" ]]; then
      run rm -rf -- "$target"
      log "removed: $target"
    fi
  done
  # INDEX file: try VIBECODE-SUITE.md too (legacy)
  for legacy in "$PREFIX/VIBECODE-SUITE.md"; do
    [[ -e "$legacy" ]] && run rm -f -- "$legacy" && log "removed legacy: $legacy"
  done
  log "Done."
  exit 0
fi

log "Installing my-vibe plugin"
log "  source : $PKG_DIR"
log "  target : $PREFIX"
log "  mode   : $MODE"
[[ "$DRY" == "1" ]] && warn "DRY RUN — no changes will be written"

run mkdir -p "$PREFIX"

for n in $(skill_names); do
  src="$PKG_DIR/skills/$n"
  dst="$PREFIX/$n"

  if [[ -e "$dst" || -L "$dst" ]]; then
    # backup existing
    bak="${dst}.bak.$(date +%Y%m%d-%H%M%S)"
    warn "exists, backing up: $dst -> $bak"
    run mv -- "$dst" "$bak"
  fi

  if [[ "$MODE" == "symlink" ]]; then
    run ln -s "$src" "$dst"
  else
    run cp -r "$src" "$dst"
  fi
  log "installed: $n"
done

log "Skills installed. Restart Claude Code session to discover them."
log "Verify: ls $PREFIX | grep '^vc-'"
