#!/usr/bin/env bash
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "🚫 Rode como root (sudo -i)."; exit 1; }
command -v curl >/dev/null 2nd>&1 || { apt-get update -y && apt-get install -y curl ca-certificates; }

WORKDIR="/opt/captio"; mkdir -p "$WORKDIR"; cd "$WORKDIR"

# 👉 a ÚNICA linha que você muda quando lançar nova versão:
MENU_URL="https://raw.githubusercontent.com/cfjacques/captio-setup/v1.0/SetupCaptio"

curl -fsSL "$MENU_URL" -o SetupCaptio
chmod +x SetupCaptio
exec ./SetupCaptio
