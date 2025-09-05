#!/usr/bin/env bash
set -euo pipefail

# CAPTIO Setup bootstrap (rebrand + banner + patches) – v0.5
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

# ─────────────────────────────────────────────────────────────
# Banner CAPTIO (garantido aparecer antes de tudo)
# ─────────────────────────────────────────────────────────────
cat <<'BANNER'
   _____      _   _   _   ____  _             ____           _   _ _             
  / ____|    | | | | | | / __ \| |           / __ \         | | (_) |            
 | |     __ _| |_| |_| || |  | | |_ _ __ ___| |  | |_ __ ___| |_ _| |_ ___  _ __ 
 | |    / _` | __| __| || |  | | __| '__/ _ \ |  | | '__/ __| __| | __/ _ \| '__|
 | |___| (_| | |_| |_| || |__| | |_| | |  __/ |__| | |  \__ \ |_| | || (_) | |   
  \_____\__,_|\__|\__|_| \____/ \__|_|  \___|\____/|_|  |___/\__|_|\__\___/|_|   

                              SETUP CAPTIO  1.0
---------------------------------------------------------------------------------
BANNER

SRC_URL="https://raw.githubusercontent.com/oriondesign2015/SetupOrion/main/SetupOrion"
DST_FILE="SetupCaptio"
rm -f "$DST_FILE"

echo "↓ Baixando menu base..."
curl -fsSL "$SRC_URL" -o "$DST_FILE"

# ─────────────────────────────────────────────────────────────
# Rebrand agressivo (nome, domínio, ocorrências isoladas)
# ─────────────────────────────────────────────────────────────
# nomes “óbvios”
sed -i 's/ORION DESIGN/CAPTIO AI/g' "$DST_FILE"
sed -i 's/SetupOrion/SetupCaptio/g' "$DST_FILE"
sed -i 's/oriondesign\.art\.br/captioai.com/g' "$DST_FILE"
sed -i 's/OrionDesign/CAPTIOAI/g' "$DST_FILE"

# qualquer “SETUP ORION” → “SETUP CAPTIO” (mesmo sem o “SETUP ” junto)
sed -i -E 's/\bSETUP[[:space:]]*ORION\b/SETUP CAPTIO/g' "$DST_FILE"
sed -i -E 's/\bORION\b/CAPTIO/g' "$DST_FILE"

# trocar versão no banner “- X.Y.Z -” por “- 1.0 -” (mesmo com espaçamentos)
sed -i -E 's/-[[:space:]]*[0-9]+(\.[0-9]+){1,2}[[:space:]]*-/ - 1.0 -/g' "$DST_FILE"

# se existir linha “Versão do Setup...” troca pra nossa
sed -i 's/Versão do SetupOrion:/Versão do SetupCaptio:/g' "$DST_FILE"
sed -i 's/Versão do SetupCaptio: \\e\[32mv\.[^\\]*\\e\[0m/Versão do SetupCaptio: \\e[32mv. 1.0\\e[0m/g' "$DST_FILE" || true

# ─────────────────────────────────────────────────────────────
# Evolution API – fixo v2.2.3 + phone version + client
# ─────────────────────────────────────────────────────────────
sed -i 's@\bimage:\s*atendai/evolution-api:[^"'"'"' ]*@image: atendai/evolution-api:v2.2.3@g' "$DST_FILE" || true
sed -i 's@\bimage:\s*evoapicloud/evolution-api:[^"'"'"' ]*@image: atendai/evolution-api:v2.2.3@g' "$DST_FILE" || true
sed -i 's@#- CONFIG_SESSION_PHONE_VERSION=.*@- CONFIG_SESSION_PHONE_VERSION=2.3000.1023015479@g' "$DST_FILE" || true
sed -i 's@CONFIG_SESSION_PHONE_CLIENT=.*@CONFIG_SESSION_PHONE_CLIENT=CAPTIOAI@g' "$DST_FILE" || true
sed -i 's@#- CONFIG_SESSION_PHONE_CLIENT=.*@- CONFIG_SESSION_PHONE_CLIENT=CAPTIOAI@g' "$DST_FILE" || true

# ─────────────────────────────────────────────────────────────
# Chatwoot – perguntas IG/FB somente no fluxo do Chatwoot
#   1) inserir perguntas após a porta SMTP
#   2) ativar envs no YAML se valores existirem
# ─────────────────────────────────────────────────────────────
sed -i '/Digite a porta SMTP do Email (ex: 465): \\\e\[0m\" && read -r porta_smtp_chatwoot/a \
    \ \ \ \ echo \"\"\\n\
    \ \ \ \ echo -e \"\\e[97mIntegração opcional: Instagram/Facebook (ENTER para pular)\\e[0m\"\\n\
    \ \ \ \ echo -en \"\\e[33mFB_APP_ID: \\e[0m\" \&\& read -r FB_APP_ID\\n\
    \ \ \ \ echo -en \"\\e[33mFB_APP_SECRET: \\e[0m\" \&\& read -r FB_APP_SECRET\\n\
    \ \ \ \ echo -en \"\\e[33mFB_VERIFY_TOKEN: \\e[0m\" \&\& read -r FB_VERIFY_TOKEN\\n\
    \ \ \ \ echo -en \"\\e[33mIG_VERIFY_TOKEN: \\e[0m\" \&\& read -r IG_VERIFY_TOKEN\\n' "$DST_FILE" || true

sed -i '/STACK_NAME=\"chatwoot\${1:\+_\$1}\"/i \
    \ \ \ \ # Ativa envs do Facebook/Instagram no YAML se informadas\\n\
    \ \ \ \ if [ -n \"\${FB_APP_ID:-}\" ]; then sed -i \"s/#- FB_APP_ID=.*/- FB_APP_ID=\${FB_APP_ID}/\" chatwoot\${1:+_\$1}.yaml; fi\\n\
    \ \ \ \ if [ -n \"\${FB_APP_SECRET:-}\" ]; then sed -i \"s/#- FB_APP_SECRET=.*/- FB_APP_SECRET=\${FB_APP_SECRET}/\" chatwoot\${1:+_\$1}.yaml; fi\\n\
    \ \ \ \ if [ -n \"\${FB_VERIFY_TOKEN:-}\" ]; then sed -i \"s/#- FB_VERIFY_TOKEN=.*/- FB_VERIFY_TOKEN=\${FB_VERIFY_TOKEN}/\" chatwoot\${1:+_\$1}.yaml; fi\\n\
    \ \ \ \ if [ -n \"\${IG_VERIFY_TOKEN:-}\" ]; then sed -i \"s/#- IG_VERIFY_TOKEN=.*/- IG_VERIFY_TOKEN=\${IG_VERIFY_TOKEN}/\" chatwoot\${1:+_\$1}.yaml; fi\\n' "$DST_FILE" || true

chmod +x "$DST_FILE"

echo
echo "✅ CAPTIO patches aplicados. Iniciando menu..."
exec ./"$DST_FILE"
