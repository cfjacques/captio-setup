#!/usr/bin/env bash
set -e
# CAPTIO Setup bootstrap
if [ "$(id -u)" -ne 0 ]; then echo "🚫 Rode como root (sudo -i)."; exit 1; fi
if ! command -v curl >/dev/null 2>&1; then apt-get update -y && apt-get install -y curl ca-certificates; fi
WORKDIR="/opt/captio"; mkdir -p "$WORKDIR"; cd "$WORKDIR"
MENU_URL="https://raw.githubusercontent.com/cfjacques/captio-setup/main/SetupCaptio"
curl -fsSL "$MENU_URL" -o SetupCaptio
chmod +x SetupCaptio
exec ./SetupCaptio
