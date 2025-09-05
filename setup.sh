#!/usr/bin/env bash
set -euo pipefail

# CAPTIO Setup bootstrap (rebrand + banner override + patches) – v0.6
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

SRC_URL="https://raw.githubusercontent.com/oriondesign2015/SetupOrion/main/SetupOrion"
DST_FILE="SetupCaptio"
TMP_OUT="$DST_FILE.tmp"

echo "↓ Baixando menu base..."
curl -fsSL "$SRC_URL" -o "$DST_FILE"

# ─────────────────────────────────────────────────────────────
# 1) REBRAND textual básico
# ─────────────────────────────────────────────────────────────
sed -i 's/ORION DESIGN/CAPTIO AI/g' "$DST_FILE"
sed -i 's/SetupOrion/SetupCaptio/g' "$DST_FILE"
sed -i 's/oriondesign\.art\.br/captioai.com/g' "$DST_FILE"
sed -i 's/OrionDesign/CAPTIOAI/g' "$DST_FILE"
sed -i 's/Versão do SetupOrion:/Versão do SetupCaptio:/g' "$DST_FILE" || true

# ─────────────────────────────────────────────────────────────
# 2) Evolution API – fixo v2.2.3 + phone version + client
# ─────────────────────────────────────────────────────────────
sed -i 's@\bimage:\s*atendai/evolution-api:[^"'"'"' ]*@image: atendai/evolution-api:v2.2.3@g' "$DST_FILE" || true
sed -i 's@\bimage:\s*evoapicloud/evolution-api:[^"'"'"' ]*@image: atendai/evolution-api:v2.2.3@g' "$DST_FILE" || true
sed -i 's@#- CONFIG_SESSION_PHONE_VERSION=.*@- CONFIG_SESSION_PHONE_VERSION=2.3000.1023015479@g' "$DST_FILE" || true
sed -i 's@CONFIG_SESSION_PHONE_CLIENT=.*@CONFIG_SESSION_PHONE_CLIENT=CAPTIOAI@g' "$DST_FILE" || true
sed -i 's@#- CONFIG_SESSION_PHONE_CLIENT=.*@- CONFIG_SESSION_PHONE_CLIENT=CAPTIOAI@g' "$DST_FILE" || true

# ─────────────────────────────────────────────────────────────
# 3) Chatwoot – perguntas FB/IG só no fluxo do Chatwoot
#    (após pergunta da porta SMTP) + ativação condicional no YAML
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

# ─────────────────────────────────────────────────────────────
# 4) Substituir a FUNÇÃO do banner (nome_aviso) pelo nosso
#    => remove/comenta bloco original e injeta o CAPTIO no MESMO lugar
# ─────────────────────────────────────────────────────────────

# Cria arquivo com a nova função (banner CAPTIO 1.0)
cat > /opt/captio/_captio_nome_aviso.func <<'EOF_FUNC'
nome_aviso(){
  clear
  echo ""
  echo -e "$amarelo===================================================================================================$reset"
  echo -e "$amarelo=                                                                                               =$reset"
  echo -e "$amarelo=     $branco   _____      _   _   _   ____  _             ____           _   _ _              $amarelo=$reset"
  echo -e "$amarelo=     $branco  / ____|    | | | | | | / __ \| |           / __ \         | | (_) |             $amarelo=$reset"
  echo -e "$amarelo=     $branco | |     __ _| |_| |_| || |  | | |_ _ __ ___| |  | |_ __ ___| |_ _| |_ ___  _ __  $amarelo=$reset"
  echo -e "$amarelo=     $branco | |    / _\` | __| __| || |  | | __| '__/ _ \ |  | | '__/ __| __| | __/ _ \| '__| $amarelo=$reset"
  echo -e "$amarelo=     $branco | |___| (_| | |_| |_| || |__| | |_| | |  __/ |__| | |  \__ \ |_| | || (_) | |    $amarelo=$reset"
  echo -e "$amarelo=     $branco  \_____\__,_|\__|\__|_| \____/ \__|_|  \___|\____/|_|  |___/\__|_|\__\___/|_|    $amarelo=$reset"
  echo -e "$amarelo=                                                                                               =$reset"
  echo -e "$amarelo=                                         SETUP CAPTIO  -  1.0                                  =$reset"
  echo -e "$amarelo=                                                                                               =$reset"
  echo -e "$amarelo===================================================================================================$reset"
  echo ""
  echo ""
}
EOF_FUNC

# Usa awk para substituir o bloco da função nome_aviso() { ... }
awk -v repl="/opt/captio/_captio_nome_aviso.func" '
  BEGIN{inblock=0}
  /^nome_aviso[[:space:]]*\(\)[[:space:]]*{/ {
     # imprime a função nova no lugar
     while ((getline L < repl) > 0) print L
     close(repl)
     inblock=1
     next
  }
  inblock==1 && /^}/ { inblock=0; next }   # consome o "}" original
  inblock==1 { next }                      # descarta linhas internas do bloco antigo
  { print }
' "$DST_FILE" > "$TMP_OUT" && mv "$TMP_OUT" "$DST_FILE"

chmod +x "$DST_FILE"

echo
echo "✅ CAPTIO patches aplicados (banner trocado no mesmo local). Iniciando menu..."
exec ./"$DST_FILE"
