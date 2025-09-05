#!/usr/bin/env bash
set -euo pipefail

# CAPTIO Setup bootstrap (banner override + versao + patches) – v0.7

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
# Rebrand textual básico (site / nome)
# ─────────────────────────────────────────────────────────────
sed -i 's/ORION DESIGN/CAPTIO AI/g' "$DST_FILE"
sed -i 's/SetupOrion/SetupCaptio/g' "$DST_FILE"
sed -i 's/oriondesign\.art\.br/captioai.com/g' "$DST_FILE"
sed -i 's/Versão do SetupOrion:/Versão do SetupCaptio:/g' "$DST_FILE" || true

# ─────────────────────────────────────────────────────────────
# Evolution API – fixo v2.2.3 + phone version + client
# ─────────────────────────────────────────────────────────────
sed -i 's@\bimage:\s*atendai/evolution-api:[^"'"'"' ]*@image: atendai/evolution-api:v2.2.3@g' "$DST_FILE" || true
sed -i 's@\bimage:\s*evoapicloud/evolution-api:[^"'"'"' ]*@image: atendai/evolution-api:v2.2.3@g' "$DST_FILE" || true
sed -i 's@#- CONFIG_SESSION_PHONE_VERSION=.*@- CONFIG_SESSION_PHONE_VERSION=2.3000.1023015479@g' "$DST_FILE" || true
sed -i 's@CONFIG_SESSION_PHONE_CLIENT=.*@CONFIG_SESSION_PHONE_CLIENT=CAPTIOAI@g' "$DST_FILE" || true
sed -i 's@#- CONFIG_SESSION_PHONE_CLIENT=.*@- CONFIG_SESSION_PHONE_CLIENT=CAPTIOAI@g' "$DST_FILE" || true

# ─────────────────────────────────────────────────────────────
# Chatwoot – perguntas FB/IG só no fluxo do Chatwoot
# (após pergunta da porta SMTP) + ativação condicional no YAML
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
# OVERRIDE de FUNÇÕES: banner gigante e linha de versão
#   - Substitui nome_instalador() (banner ASCII grande)
#   - Substitui versao() (texto “Versão do Setup… v. 1.0” + link do site)
# ─────────────────────────────────────────────────────────────

# (A) nova função nome_instalador()
cat > /opt/captio/_func_nome_instalador <<'EOF_FUNC_A'
nome_instalador() { 
    clear
    echo ""
    echo -e "$amarelo===================================================================================================\e[0m"
    echo -e "$amarelo=                                                                                                 =\e[0m"
    echo -e "$branco       ███████╗███████╗████████╗██╗   ██╗██████╗       ██████╗ █████╗ ██████╗ ████████╗██╗ ██████╗  \e[0m"
    echo -e "$branco       ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗      ██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗ \e[0m"
    echo -e "$branco       ███████╗█████╗     ██║   ██║   ██║██████╔╝      ██████╔╝███████║██████╔╝   ██║   ██║██║   ██║ \e[0m"
    echo -e "$branco       ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝       ██╔══██╗██╔══██║██╔══██╗   ██║   ██║██║   ██║ \e[0m"
    echo -e "$branco       ███████║███████╗   ██║   ╚██████╔╝██║           ██║  ██║██║  ██║██║  ██║   ██║   ██║╚██████╔╝ \e[0m"
    echo -e "$branco       ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝           ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝  \e[0m"
    echo -e "$amarelo=                                                                                                 =\e[0m"
    echo -e "$amarelo=                                        SETUP CAPTIO  -  1.0                                     =\e[0m"
    echo -e "$amarelo=                                                                                                 =\e[0m"
    echo -e "$amarelo===================================================================================================\e[0m"
    echo ""
}
EOF_FUNC_A

# (B) nova função versao()
cat > /opt/captio/_func_versao <<'EOF_FUNC_B'
versao() {
echo -e "                                   \e[97mVersão do SetupCaptio: \e[32mv. 1.0\e[0m                                  "
echo -e "\e[32mcaptioai.com/setup\e[0m"
}
EOF_FUNC_B

# utilitário awk para substituir função por outra
replace_func () {
  local func="$1" srcfile="$2" newfile="$3" ; local tmp="${srcfile}.tmp.$$"
  awk -v name="$func" -v repl="$newfile" '
    BEGIN{inblock=0}
    $0 ~ "^[[:space:]]*"name"[[:space:]]*\\(\\)[[:space:]]*\\{" {
      while ((getline L < repl) > 0) print L
      close(repl)
      inblock=1
      next
    }
    inblock==1 && /^}/ { inblock=0; next }
    inblock==1 { next }
    { print }
  ' "$srcfile" > "$tmp" && mv "$tmp" "$srcfile"
}

# aplica overrides
replace_func "nome_instalador" "$DST_FILE" "/opt/captio/_func_nome_instalador"
replace_func "versao"          "$DST_FILE" "/opt/captio/_func_versao"

chmod +x "$DST_FILE"

echo
echo "✅ CAPTIO patches aplicados (banner + versão). Iniciando menu..."
exec ./"$DST_FILE"
