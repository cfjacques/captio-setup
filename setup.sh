#!/usr/bin/env bash
set -euo pipefail

# CAPTIO Setup bootstrap (rebrand + targeted patches) – v0.3
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

SRC_URL="https://raw.githubusercontent.com/oriondesign2015/SetupOrion/main/SetupOrion" # menu base (temporário)
DST_FILE="SetupCaptio"

echo "↓ Baixando menu base..."
curl -fsSL "$SRC_URL" -o "$DST_FILE"

# ------------------------------------------------------------------
# REBRAND CAPTIO + versão + ajustes Evolution + perguntas Chatwoot
# ------------------------------------------------------------------

# Branding / textos gerais
sed -i 's/ORION DESIGN/CAPTIO AI/g' "$DST_FILE"
sed -i 's/SetupOrion/SetupCaptio/g' "$DST_FILE"
sed -i 's/oriondesign\.art\.br/captioai.com/g' "$DST_FILE"
sed -i 's/OrionDesign/CAPTIOAI/g' "$DST_FILE"

# Versão no cabeçalho (mostra “Versão do SetupCaptio: v. 1.0”)
sed -i 's/Versão do SetupCaptio: \\e\[32mv\.[^\\]*\\e\[0m/Versão do SetupCaptio: \\e[32mv. 1.0\\e[0m/g' "$DST_FILE" || true
sed -i 's/Versão do SetupOrion: \\e\[32mv\.[^\\]*\\e\[0m/Versão do SetupCaptio: \\e[32mv. 1.0\\e[0m/g' "$DST_FILE" || true

# Evolution API – fixar versão e client/phone version
sed -i 's@\bimage:\s*atendai/evolution-api:[^"'"'"' ]*@image: atendai/evolution-api:v2.2.3@g' "$DST_FILE"
sed -i 's@\bimage:\s*evoapicloud/evolution-api:[^"'"'"' ]*@image: atendai/evolution-api:v2.2.3@g' "$DST_FILE"
sed -i 's@#- CONFIG_SESSION_PHONE_VERSION=.*@- CONFIG_SESSION_PHONE_VERSION=2.3000.1023015479@g' "$DST_FILE"
sed -i 's@CONFIG_SESSION_PHONE_CLIENT=.*@CONFIG_SESSION_PHONE_CLIENT=CAPTIOAI@g' "$DST_FILE"
sed -i 's@#- CONFIG_SESSION_PHONE_CLIENT=.*@- CONFIG_SESSION_PHONE_CLIENT=CAPTIOAI@g' "$DST_FILE"

# ------------------------------------------------------------
# Chatwoot (perguntas IG/FB só no fluxo do Chatwoot)
# 1) Inserir perguntas após a coleta de SMTP (porta)
# 2) Ativar envs no YAML gerado, se preenchidos
# ------------------------------------------------------------

# (1) Inserir perguntas no lugar certo do fluxo do Chatwoot
sed -i '/Digite a porta SMTP do Email (ex: 465): \\\e\[0m\" && read -r porta_smtp_chatwoot/a \
    \ \ \ \ echo \"\"\\n\
    \ \ \ \ echo -e \"\\e[97mIntegração opcional: Instagram/Facebook (pressione ENTER para pular)\\e[0m\"\\n\
    \ \ \ \ echo -en \"\\e[33mFB_APP_ID: \\e[0m\" \&\& read -r FB_APP_ID\\n\
    \ \ \ \ echo -en \"\\e[33mFB_APP_SECRET: \\e[0m\" \&\& read -r FB_APP_SECRET\\n\
    \ \ \ \ echo -en \"\\e[33mFB_VERIFY_TOKEN: \\e[0m\" \&\& read -r FB_VERIFY_TOKEN\\n\
    \ \ \ \ echo -en \"\\e[33mIG_VERIFY_TOKEN: \\e[0m\" \&\& read -r IG_VERIFY_TOKEN\\n' "$DST_FILE" || true

# (2) Antes do deploy do Chatwoot, habilitar as linhas do YAML se os valores foram informados
sed -i '/STACK_NAME=\"chatwoot\${1:\+_\$1}\"/i \
    \ \ \ \ # Ativa envs do Facebook/Instagram no YAML se informadas\\n\
    \ \ \ \ if [ -n \"\${FB_APP_ID:-}\" ]; then sed -i \"s/#- FB_APP_ID=.*/- FB_APP_ID=\${FB_APP_ID}/\" chatwoot\${1:+_\$1}.yaml; fi\\n\
    \ \ \ \ if [ -n \"\${FB_APP_SECRET:-}\" ]; then sed -i \"s/#- FB_APP_SECRET=.*/- FB_APP_SECRET=\${FB_APP_SECRET}/\" chatwoot\${1:+_\$1}.yaml; fi\\n\
    \ \ \ \ if [ -n \"\${FB_VERIFY_TOKEN:-}\" ]; then sed -i \"s/#- FB_VERIFY_TOKEN=.*/- FB_VERIFY_TOKEN=\${FB_VERIFY_TOKEN}/\" chatwoot\${1:+_\$1}.yaml; fi\\n\
    \ \ \ \ if [ -n \"\${IG_VERIFY_TOKEN:-}\" ]; then sed -i \"s/#- IG_VERIFY_TOKEN=.*/- IG_VERIFY_TOKEN=\${IG_VERIFY_TOKEN}/\" chatwoot\${1:+_\$1}.yaml; fi\\n' "$DST_FILE" || true

chmod +x "$DST_FILE"

echo
echo "✅ CAPTIO patches prontos. Iniciando menu..."
exec ./"$DST_FILE"
