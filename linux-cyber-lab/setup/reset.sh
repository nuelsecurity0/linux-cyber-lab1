#!/usr/bin/env bash
#
# reset.sh - teardown + setup (recomeca o laboratorio do zero)
#
# Uso: sudo ./setup/reset.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ $EUID -eq 0 ]] || { echo "Execute como root: sudo ./setup/reset.sh"; exit 1; }

echo "[i] Resetando o laboratorio..."
"$SCRIPT_DIR/teardown.sh"
echo
"$SCRIPT_DIR/setup.sh"
