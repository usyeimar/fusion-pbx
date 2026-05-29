#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# FusionPBX container entrypoint
#   1. Prints a startup dashboard (system + components + access)
#   2. Waits for PostgreSQL to be ready
#   3. Hands off to supervisord (nginx + php-fpm + FreeSWITCH)
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' C='\033[0;36m' B='\033[1;34m'
W='\033[1;37m' N='\033[0m' DIM='\033[2m'

DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-fusionpbx}"
DB_USER="${DB_USER:-fusionpbx}"

banner() {
echo ""
echo -e "  ${B}███████╗██╗   ██╗███████╗██╗ ██████╗ ███╗   ██╗██████╗ ██████╗ ██╗  ██╗${N}"
echo -e "  ${B}██╔════╝██║   ██║██╔════╝██║██╔═══██╗████╗  ██║██╔══██╗██╔══██╗╚██╗██╔╝${N}"
echo -e "  ${B}█████╗  ██║   ██║███████╗██║██║   ██║██╔██╗ ██║██████╔╝██████╔╝ ╚███╔╝ ${N}"
echo -e "  ${B}██╔══╝  ██║   ██║╚════██║██║██║   ██║██║╚██╗██║██╔═══╝ ██╔══██╗ ██╔██╗ ${N}"
echo -e "  ${B}██║     ╚██████╔╝███████║██║╚██████╔╝██║ ╚████║██║     ██████╔╝██╔╝ ██╗${N}"
echo -e "  ${B}╚═╝      ╚═════╝ ╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═════╝ ╚═╝  ╚═╝${N}"
echo -e "                  ${W}VoIP / Telephony PBX on FreeSWITCH${N}"
echo ""
}

log()  { echo -e "  ${C}[$(date +%H:%M:%S)]${N} $1"; }
ok()   { echo -e "  ${G}[$(date +%H:%M:%S)] ✔${N} $1"; }
warn() { echo -e "  ${Y}[$(date +%H:%M:%S)] ⚠${N} $1"; }
info() { echo -e "  ${DIM}  ├─${N} $1"; }
last() { echo -e "  ${DIM}  └─${N} $1"; }
sep()  { echo -e "  ${DIM}─────────────────────────────────────────────────────────${N}"; }

# Apply timezone if provided
if [[ -n "${TZ:-}" && -f "/usr/share/zoneinfo/${TZ}" ]]; then
  ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime 2>/dev/null || true
fi

banner

sep
echo -e "  ${W}SYSTEM${N}"
info "OS:          $(grep PRETTY /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '\"')"
info "Kernel:      $(uname -r)"
info "Hostname:    $(hostname)"
info "IP:          $(hostname -i 2>/dev/null | awk '{print $1}')"
info "CPU:         $(nproc) cores"
info "RAM:         $(free -h 2>/dev/null | awk '/Mem:/{print $2}') total"
last "Timezone:    ${TZ:-UTC}"
echo ""

sep
echo -e "  ${W}COMPONENTS${N}"
info "FreeSWITCH:  $(command -v freeswitch >/dev/null && freeswitch -version 2>/dev/null | awk '{print $3}' || echo 'n/a')"
info "PHP:         $(command -v php >/dev/null && php -v 2>/dev/null | head -1 | awk '{print $2}' || echo 'n/a')"
info "NGINX:       $(command -v nginx >/dev/null && nginx -v 2>&1 | awk -F/ '{print $2}' || echo 'n/a')"
last "PostgreSQL:  client $(command -v psql >/dev/null && psql --version 2>/dev/null | awk '{print $3}' || echo 'n/a')"
echo ""

db_ready() {
  if command -v pg_isready >/dev/null 2>&1; then
    pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" >/dev/null 2>&1
  else
    # Fallback: plain TCP check so we never hang if pg_isready is unavailable
    (exec 3<>"/dev/tcp/${DB_HOST}/${DB_PORT}") 2>/dev/null
  fi
}

sep
echo -e "  ${W}DATABASE${N}"
log "Waiting for PostgreSQL at ${DB_HOST}:${DB_PORT} ..."
until db_ready; do
  printf '  .'
  sleep 1
done
echo ""
ok "PostgreSQL is ready (db=${DB_NAME}, user=${DB_USER})"
echo ""

sep
echo ""
echo -e "  ${G}┌─────────────────────────────────────────────────────────┐${N}"
echo -e "  ${G}│  ${W}✔ FusionPBX — starting services${G}                        │${N}"
echo -e "  ${G}│                                                         │${N}"
echo -e "  ${G}│  ${N}Web UI       ${C}http://localhost:8080  ·  https://localhost:8443${N}"
echo -e "  ${G}│  ${N}SIP          ${C}host :5060 (UDP/TCP)  ·  :5080${N}"
echo -e "  ${G}│  ${N}RTP          ${C}16384-16390 (UDP)${N}"
echo -e "  ${G}│  ${N}Database     ${C}${DB_HOST}:${DB_PORT}${N}"
echo -e "  ${G}│                                                         │${N}"
echo -e "  ${G}└─────────────────────────────────────────────────────────┘${N}"
echo ""
echo -e "  ${DIM}First run opens the FusionPBX install wizard at the Web UI.${N}"
echo -e "  ${DIM}Handing off to supervisord (nginx + php-fpm + FreeSWITCH)...${N}"
echo ""

exec /usr/bin/supervisord -n
