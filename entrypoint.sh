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

# ─────────────────────────────────────────────────────────────────────────────
# Provision FusionPBX: write config.conf from env, then install schema + a
# superadmin user on first boot (mirrors the official fusionpbx-install finish).
# ─────────────────────────────────────────────────────────────────────────────
FUSIONPBX_ROOT="/var/www/fusionpbx"
CONF="/etc/fusionpbx/config.conf"
export PGPASSWORD="${DB_PASS:-}"
PSQL="psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME}"

sep
echo -e "  ${W}FUSIONPBX${N}"

# Always (re)write config.conf so the DB connection matches the environment
mkdir -p /etc/fusionpbx /var/cache/fusionpbx
cat > "$CONF" <<CONF
#database system settings
database.0.type = pgsql
database.0.host = ${DB_HOST}
database.0.port = ${DB_PORT}
database.0.sslmode = prefer
database.0.name = ${DB_NAME}
database.0.username = ${DB_USER}
database.0.password = ${DB_PASS:-}
#database switch settings
database.1.type = sqlite
database.1.path = /var/lib/freeswitch/db
database.1.name = core.db
#general settings
document.root = ${FUSIONPBX_ROOT}
project.path =
temp.dir = /tmp
php.dir = /usr/bin
php.bin = php
#session settings
session.cookie_httponly = true
session.cookie_secure = true
session.cookie_samesite = Lax
#cache settings
cache.method = file
cache.location = /var/cache/fusionpbx
cache.settings = true
#switch settings
switch.conf.dir = /etc/freeswitch
switch.sounds.dir = /usr/share/freeswitch/sounds
switch.database.dir = /var/lib/freeswitch/db
switch.recordings.dir = /var/lib/freeswitch/recordings
switch.storage.dir = /var/lib/freeswitch/storage
switch.voicemail.dir = /var/lib/freeswitch/storage/voicemail
switch.scripts.dir = /usr/share/freeswitch/scripts
#xml handler
xml_handler.fs_path = false
xml_handler.reg_as_number_alias = false
xml_handler.number_as_presence_id = true
#error reporting options: user,dev,all
error.reporting = user
CONF
chown -R www-data:www-data /etc/fusionpbx /var/cache/fusionpbx 2>/dev/null || true
info "config.conf -> ${DB_HOST}:${DB_PORT}/${DB_NAME}"

# Build the schema if the users table is missing
if ! $PSQL -tAc "select to_regclass('public.v_users')" 2>/dev/null | grep -q v_users; then
  log "Building FusionPBX schema (first run, may take a moment)..."
  ( cd "$FUSIONPBX_ROOT" && php core/upgrade/upgrade.php --schema >/dev/null 2>&1 )
  ok "Schema created"
fi

# Create a default domain + superadmin if there are no users yet
USER_COUNT=$($PSQL -tAc "select count(*) from v_users" 2>/dev/null | tr -d '[:space:]' || echo 0)
if [ "${USER_COUNT:-0}" = "0" ]; then
  FPBX_DOMAIN="${FUSIONPBX_DOMAIN:-localhost}"
  FPBX_USER="${FUSIONPBX_ADMIN_USER:-admin}"
  GEN_PW=""
  if [ -z "${FUSIONPBX_ADMIN_PASSWORD:-}" ]; then
    FUSIONPBX_ADMIN_PASSWORD=$(php -r 'echo bin2hex(random_bytes(8));')
    GEN_PW=1
  fi
  log "Provisioning domain '${FPBX_DOMAIN}' and superadmin '${FPBX_USER}'..."
  domain_uuid=$(php "$FUSIONPBX_ROOT/resources/uuid.php")
  $PSQL -c "insert into v_domains (domain_uuid, domain_name, domain_enabled) values('$domain_uuid','${FPBX_DOMAIN}','true');" >/dev/null 2>&1
  ( cd "$FUSIONPBX_ROOT" && php core/upgrade/upgrade.php --defaults >/dev/null 2>&1 )
  user_uuid=$(php "$FUSIONPBX_ROOT/resources/uuid.php")
  user_salt=$(php "$FUSIONPBX_ROOT/resources/uuid.php")
  pw_hash=$(php -r "echo md5('${user_salt}${FUSIONPBX_ADMIN_PASSWORD}');")
  $PSQL -c "insert into v_users (user_uuid, domain_uuid, username, password, salt, user_enabled) values('$user_uuid','$domain_uuid','${FPBX_USER}','$pw_hash','$user_salt','true');" >/dev/null 2>&1
  group_uuid=$($PSQL -qtAX -c "select group_uuid from v_groups where group_name='superadmin';" 2>/dev/null | head -1 | tr -d '[:space:]')
  user_group_uuid=$(php "$FUSIONPBX_ROOT/resources/uuid.php")
  $PSQL -c "insert into v_user_groups (user_group_uuid, domain_uuid, group_name, group_uuid, user_uuid) values('$user_group_uuid','$domain_uuid','superadmin','$group_uuid','$user_uuid');" >/dev/null 2>&1
  ( cd "$FUSIONPBX_ROOT" && php core/upgrade/upgrade.php --defaults >/dev/null 2>&1 && php core/upgrade/upgrade.php --permissions >/dev/null 2>&1 )
  ok "FusionPBX installed"
  echo ""
  echo -e "  ${G}┌─ FusionPBX admin login ─────────────────────────────────┐${N}"
  echo -e "  ${G}│${N}  domain:   ${C}${FPBX_DOMAIN}${N}"
  echo -e "  ${G}│${N}  username: ${C}${FPBX_USER}${N}"
  echo -e "  ${G}│${N}  password: ${C}${FUSIONPBX_ADMIN_PASSWORD}${N}"
  [ -n "$GEN_PW" ] && echo -e "  ${G}│${N}  ${Y}(auto-generated — set FUSIONPBX_ADMIN_PASSWORD in .env to pin it)${N}"
  echo -e "  ${G}└─────────────────────────────────────────────────────────┘${N}"
else
  info "already installed (${USER_COUNT} user(s)) — skipping"
fi
unset PGPASSWORD
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
