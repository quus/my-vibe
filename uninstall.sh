#!/usr/bin/env bash
# Thin wrapper for install.sh --uninstall
exec "$(dirname "${BASH_SOURCE[0]}")/install.sh" --uninstall "$@"
