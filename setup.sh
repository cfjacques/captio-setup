#!/usr/bin/env bash
set -euo pipefail

# CAPTIO Setup bootstrap (rebrand + patches) – v0.2
# Requisitos: root (sudo -i) em Ubuntu/Debian

if [ "$(id -u)" -ne 0 ]; then
  echo "🚫 Rode como root (sudo -i)."
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  apt-get update -y && apt-get install -y curl ca-certificates
fi

WORKDIR="/opt/captio"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

SRC_URL="https://raw.githubusercontent.com/oriondesign2015/SetupOrion/main/SetupOrion" # menu base
DST_FILE="SetupCaptio"

echo "↓ Baixando menu base..."
curl -fsSL "$SRC_URL" -o "$DST_FILE"

# ------------------------------------------------------------
# REBRAND CAPTIO + ajustes Evolution + Chatwoot IG/FB
# ------------------------------------------------------------

# Branding
sed -i 's/ORION DESIGN/CAPTIO AI/g' "$DST_FILE"
sed -i 's/SetupOrion/SetupCaptio/g' "$DST_FILE"
sed -i 's/oriondesign\.art\.br/captioai.com/g' "$DST_FILE"
sed -i 's/OrionDesign/CAPTIOAI/g' "$DST_FILE"

# Evolution API – fixar versão e cliente/phone
# (existem variações no script original; cobrimos todas)
sed -i 's@\bimage:\s*evoapicloud/evolution-api:[^"'"'"' ]*@image: atendai/evolution-api:v2.2.3@g' "$DST_FILE"
sed -i 's@\bimage:\s*atendai/evolution-api-lite:[^"'"'"' ]*@image: atendai/evolution-api:v2.2.3@g' "$DST_FILE"
sed -i 's@\bimage:\s*atendai/evolution-api:[^"'"'"' ]*@image: atendai/evolution-api:v2.2.3@g' "$DST_FILE"

# Descomentar/forçar CONFIG_SESSION_PHONE_VERSION e CLIENT
sed -i 's@#- CONFIG_SESSION_PHONE_VERSION=.*@- CONFIG_SESSION_PHONE_VERSION=2.3000.1023015479@g' "$DST_FILE"
sed -i 's@CONFIG_SESSION_PHONE_CLIENT=.*@CONFIG_SESSION_PHONE_CLIENT=CAPTIOAI@g' "$DST_FILE"
# Se a linha acima estiver comentada em algum ponto, garante descomentado:
sed -i 's@#- CONFIG_SESSION_PHONE_CLIENT=.*@- CONFIG_SESSION_PHONE_CLIENT=CAPTIOAI@g' "$DST_FILE"

# ------------------------------------------------------------
# Perguntas opcionais para Chatwoot (Facebook/Instagram)
# Se preencher, ativamos as envs no YAML; se deixar vazio, ficam comentadas.
# ------------------------------------------------------------

echo
echo ">>> Integração Chatwoot (opcional) – Instagram/Facebook"
read -rp "FB_APP_ID (enter para pular): " FB_APP_ID || true
read -rp "FB_APP_SECRET (enter para pular): " FB_APP_SECRET || true
read -rp "FB_VERIFY_TOKEN (enter para pular): " FB_VERIFY_TOKEN || true
read -rp "IG_VERIFY_TOKEN (enter para pular): " IG_VERIFY_TOKEN || true

activate_env_line() {
  local key="$1" val="$2"
  if [ -n "${val:-}" ]; then
    # ativa a linha comentada padronizada "      #- KEY="
    sed -i "s@^\\([[:space:]]\\{6\\}\\)#- ${key}=.*@      - ${key}=${val}@g" "$DST_FILE"
  fi
}

activate_env_line "FB_APP_ID"       "${FB_APP_ID:-}"
activate_env_line "FB_APP_SECRET"   "${FB_APP_SECRET:-}"
activate_env_line "FB_VERIFY_TOKEN" "${FB_VERIFY_TOKEN:-}"
activate_env_line "IG_VERIFY_TOKEN" "${IG_VERIFY_TOKEN:-}"

chmod +x "$DST_FILE"

echo
echo "✅ Patches aplicados. Iniciando o menu CAPTIO..."
exec ./"$DST_FILE"
