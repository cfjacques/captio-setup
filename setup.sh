#!/usr/bin/env bash
set -euo pipefail

# CAPTIO Setup bootstrap (rebrand + targeted patches + banner) – v0.4
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

# Menu base (temporário: baixa do repo original e aplica rebrand/patches)
SRC_URL="https://raw.githubusercontent.com/oriondesign2015/SetupOrion/main/SetupOrion"
DST_FILE="SetupCaptio"

echo "↓ Baixando menu base..."
curl -fsSL "$SRC_URL" -o "$DST_FILE"

# ------------------------------------------------------------------
# REBRAND CAPTIO + versão + BANNER ASCII
# ------------------------------------------------------------------

# Branding / textos gerais
sed -i 's/ORION DESIGN/CAPTIO AI/g' "$DST_FILE"
sed -i 's/SetupOrion/SetupCaptio/g' "$DST_FILE"
sed -i 's/oriondesign\.art\.br/captioai.com/g' "$DST_FILE"
sed -i 's/OrionDesign/CAPTIOAI/g' "$DST_FILE"

# Ajusta a linha de versão textual no cabeçalho (se existir)
sed -i 's/Versão do SetupCaptio: \\e\[32mv\.[^\\]*\\e\[0m/Versão do SetupCaptio: \\e[32mv. 1.0\\e[0m/g' "$DST_FILE" || true
sed -i 's/Versão do SetupOrion: \\e\[32mv\.[^\\]*\\e\[0m/Versão do SetupCaptio: \\e[32mv. 1.0\\e[0m/g' "$DST_FILE" || true

# 🔥 BANNER ASCII gigante
# Troca “SETUP ORION” -> “SETUP CAPTIO” no bloco ASCII
sed -i 's/SETUP ORION/SETUP CAPTIO/g' "$DST_FILE"
# Troca o sufixo de versão no banner “- X.Y.Z -” para “- 1.0 -”
# (cobre padrões com 2 ou 3 números)
sed -i -E 's/(-[[:space:]]*)([0-9]+\.[0-9]+(\.[0-9]+)?)\s*(-)/- 1.0 -/g' "$DST_FILE"

# ------------------------------------------------------------------
# Evolution API – fixar versão e client/phone version
# ------------------------------------------------------------------
sed -i 's@\bimage:\s*atendai/evolution-api:[^"'"'"' ]*@image: atendai/evolution-api:v2.2.3@g' "$DST_FILE"
sed -i 's@\bimage:\s*evoapicloud/evolution-api:[^"'"'"' ]*@image: atendai/evolution-api:v2.2.3@g' "$DST_FILE"
# garantir variáveis necessárias
sed -i 's@#- CONFIG_SESSION_PHONE_VERSION=.*@- CONFIG_SESSION_PHONE_VERSION=2.3000.1023015479@g' "$DST_FILE"
sed -i 's@CONFIG_SESSION_PHONE_CLIENT=.*@CONFIG_SESSION_PHONE_CLIENT=CAPTIOAI@g' "$DST_FILE"
sed -i 's@#- CONFIG_SESSION_PHONE_CLIENT=.*@- CONFIG_SESSION_PHONE_CLIENT=CAPTIOAI@g' "$DST_FILE"

# ------------------------------------------------------------------
# Chatwoot – perguntas IG/FB APENAS dentro do fluxo do Chatwoot
#   1) Insere perguntas após a pergunta de porta SMTP
#   2) Ativa as envs no YAML gerado SOMENTE se você preencher
# ------------------------------------------------------------------

# (1) Perguntas FB/IG depois do SMTP (ajusta o ponto exato do script original)
sed -i '/Digite a porta SMTP do Email (ex: 465): \\\e\[0m\" && read -r porta_smtp_chatwoot/a \
    \ \ \ \ echo \"\"\\n\
    \ \ \ \ echo -e \"\\e[97mIntegração opcional: Instagram/Facebook (pressione ENTER para pular)\\e[0m\"\\n\
    \ \ \ \ echo -en \"\\e[33mFB_APP_ID: \\e[0m\" \&\& read -r FB_APP_ID\\n\
    \ \ \ \ echo -en \"\\e[33mFB_APP_SECRET: \\e[0m\" \&\& read -r FB_APP_SECRET\\n\
    \ \ \ \ echo -en \"\\e[33mFB_VERIFY_TOKEN: \\e[0m\" \&\& read -r FB_VERIFY_TOKEN\\n\
    \ \ \ \ echo -en \"\\e[33mIG_VERIFY_TOKEN: \\e[0m\" \&\& read -r IG_VERIFY_TOKEN\\n' "$DST_FILE" || true

# (2) Ativa envs no YAML do Chatwoot se variáveis foram informadas
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
