# 📦 FusionPBX

> **FusionPBX + FreeSWITCH + PostgreSQL** stack — a complete VoIP/telephony PBX you can spin up with one command. Tested on **x86_64** and **armv7**.

<p>
  <img src="https://img.shields.io/badge/FusionPBX-1F75FE?logo=phone&logoColor=white" />
  <img src="https://img.shields.io/badge/FreeSWITCH-007ACC?logo=asterisk&logoColor=white" />
  <img src="https://img.shields.io/badge/PostgreSQL-4169E1?logo=postgresql&logoColor=white" />
  <img src="https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white" />
  <img src="https://img.shields.io/badge/NGINX-009639?logo=nginx&logoColor=white" />
  <img src="https://img.shields.io/badge/PHP--FPM-777BB4?logo=php&logoColor=white" />
  <img src="https://img.shields.io/badge/Supervisord-FF6600?logo=supervisord&logoColor=white" />
  <img src="https://img.shields.io/badge/Buildx-multi--arch-2496ED?logo=docker&logoColor=white" />
</p>

---

## 🎯 What this is

[**FusionPBX**](https://www.fusionpbx.com/) is the open-source web GUI for **FreeSWITCH** — together they turn a single container into a *"highly available single or multi-tenant PBX, carrier-grade switch, call center server, fax server, voicemail server and conference server"* (FusionPBX's own words). This repo packages that whole stack (PBX app + database) so it comes up with `./scripts/start.sh`, ready to receive SIP traffic and serve the web UI. The image clones the **latest FusionPBX** from git (5.5 at the time of writing).

**Why custom images instead of the official ones?**

- 🧱 **Slimmer images** — separate build/runtime stages
- 🛠️ **Build dependencies pulled from git** (no private repos required)
- 🌍 **Multi-arch ready** — x86_64 + armv7 tested, ARM via Buildx
- ⚙️ **Sensible defaults** — RTP port range, supervisor config, nginx vhost are all pre-wired

## ✨ FusionPBX features (out of the box)

- 🏢 Multi-tenant domains, extensions, and call routing
- ☎️ Call queues, ring groups, IVR, conferences, voicemail-to-email
- 🎙️ Call recording — with transcription & summary (v5.5)
- 📊 Live dashboard: active calls, CPU and network graphs over WebSockets
- 🛡️ Event Guard intrusion protection (nftables / iptables / pf)
- 📨 Fax server (fax-to-email, inbound/outbound)
- 🧩 Phone provisioning and device management

## 🏗️ Architecture

```
                ┌─────────────────────────────────────────────┐
   SIP / RTP    │              fusionpbx container             │
   traffic ───▶ │                                              │
                │   ┌──────────┐  ┌──────────┐  ┌──────────┐  │
   HTTP/S  ───▶ │   │  nginx   │  │ php-fpm  │  │FreeSWITCH│  │
   (UI)         │   └────┬─────┘  └────┬─────┘  └────┬─────┘  │
                │        └─────┬───────┴─────────────┘        │
                │              ▼                              │
                │        supervisord (process manager)        │
                └─────────────────┬────────────────────────────┘
                                  │
                                  ▼
                       ┌────────────────────┐
                       │  postgres container │
                       └────────────────────┘
```

A single **fusionpbx** container runs nginx + php-fpm + FreeSWITCH under supervisord; a separate **postgres** container holds the FusionPBX database.

## 🚀 Quickstart

### Requirements

- 🐳 Docker + Docker Compose plugin
- 🐚 Bash (the helper scripts live in `scripts/`)

### Run

```bash
git clone https://github.com/usyeimar/fusion-pbx.git
cd fusion-pbx

# 1. Configure environment
cp .env.example .env
nano .env                  # set a strong DB_PASS (and your TZ)

# 2a. Dev mode — build, start, and follow the PBX logs live
./scripts/start.sh

# 2b. Prod mode — build, start detached, print access info
./scripts/start.sh --prod
```

> The first run builds the FreeSWITCH base image from source and clones the
> **latest FusionPBX** — it takes a while. Subsequent starts are fast.

### Access the UI

- 🌐 HTTP: http://localhost:8080
- 🔒 HTTPS: https://localhost:8443

On first boot the container **installs FusionPBX automatically** — it writes `config.conf`
from the environment, builds the database schema, and creates a default domain and a
**superadmin** user. No manual install wizard needed; just log in:

| | |
|---|---|
| domain | `FUSIONPBX_DOMAIN` (default `localhost`) |
| username | `FUSIONPBX_ADMIN_USER` (default `admin`) |
| password | `FUSIONPBX_ADMIN_PASSWORD` — if left empty, a random one is generated and **printed in the container logs** (`./scripts/logs.sh`) |

## 🛠️ Scripts

Every operation is a plain Bash script under `scripts/` — no `make` required.

| Command | Description |
| --- | --- |
| `./scripts/start.sh` | **Dev**: build + up + follow PBX logs |
| `./scripts/start.sh --prod` | **Prod**: build + up detached |
| `./scripts/stop.sh` | Stop and remove the stack |
| `./scripts/logs.sh [service]` | Tail logs (all, or `fusionpbx` / `postgres`) |
| `./scripts/build.sh [base\|app\|all]` | Build the FreeSWITCH base and/or FusionPBX image |
| `./scripts/shell.sh` | Shell into the fusionpbx container |
| `./scripts/db-shell.sh` | psql into postgres |
| `./scripts/clean.sh` | Stop and wipe volumes (⚠️ destroys the DB) |

For multi-arch builds:
```bash
PLATFORM=linux/arm/v7 ./scripts/build.sh buildx
```

## 🏭 How the image is built

The stack is built in **two stages**, both from source — no opaque third-party images:

1. **FreeSWITCH base image** (`freeswitch/Dockerfile`) — compiles FreeSWITCH and its
   dependencies (spandsp, sofia-sip, libks, signalwire-c) from the official git sources
   on Debian, then ships a slimmer runtime image tagged `usyeimar/freeswitch`. This is
   the slow part (it builds a full softswitch from source) and only needs to run once.
2. **FusionPBX app image** (`Dockerfile`, `FROM usyeimar/freeswitch`) — adds nginx,
   php-fpm and supervisord, and clones the **latest FusionPBX** from git.

```bash
./scripts/build.sh base     # stage 1 — FreeSWITCH (from source, slow)
./scripts/build.sh app      # stage 2 — FusionPBX on top
./scripts/build.sh all      # both (base only if missing) — what start.sh calls
```

`./scripts/start.sh` invokes the build for you and compiles the base automatically the
first time, so a clean machine goes from `git clone` to a running PBX with one command.

## 🧩 Services

| Service | Image | Purpose |
| --- | --- | --- |
| `fusionpbx` | `usyeimar/fusionpbx:latest` | Web UI + PHP-FPM + nginx + FreeSWITCH (under supervisord) |
| `postgres` | `postgres:alpine` | FusionPBX database |

## 🔌 Ports

| Port | Protocol | Purpose |
| --- | --- | --- |
| 5060 | TCP/UDP | SIP signaling |
| 5080 | TCP/UDP | Internal SIP |
| 8080 | TCP | FusionPBX UI (HTTP) |
| 8443 | TCP | FusionPBX UI (HTTPS) |
| 16384–16390 | UDP | RTP media |

## 🔐 Database config

Configuration lives in `.env` (copy it from `.env.example`); nothing sensitive is committed.

| Variable | Default |
| --- | --- |
| `DB_HOST` | `postgres` |
| `DB_NAME` | `fusionpbx` |
| `DB_USER` | `fusionpbx` |
| `DB_PASS` | _required — set in `.env`_ |
| `TZ` | `America/Bogota` |
| `FUSIONPBX_DOMAIN` | `localhost` — domain created on first install |
| `FUSIONPBX_ADMIN_USER` | `admin` — superadmin created on first install |
| `FUSIONPBX_ADMIN_PASSWORD` | empty → random (printed in logs); set to pin it |

> ⚠️ **Security note:** `.env` is git-ignored. Set a strong `DB_PASS` and `FUSIONPBX_ADMIN_PASSWORD` before exposing this stack to anything outside your machine.

## 🧱 Devices and RTP

- RTP UDP range: `16384–16390` (matches the FreeSWITCH config baked into the image)
- Optional serial devices (`/dev/ttyUSB2`, `/dev/ttyUSB3`) for GSM/PSTN gateways are **commented out** in `compose.yml` — uncomment the `devices:` / `group_add:` block only if you have them.

## 🧭 Multi-arch builds

Pre-tested on x86_64 and armv7. To build for other platforms:

- 📖 [Docker Buildx docs](https://docs.docker.com/buildx/working-with-buildx/)
- 🐳 [docker/buildx project](https://github.com/docker/buildx/)
- 🦾 [Arm on Linux tutorial](https://community.arm.com/developer/tools-software/tools/b/tools-software-ides-blog/posts/getting-started-with-docker-for-arm-on-linux)
- 💻 [QEMU downloads](https://www.qemu.org/download/)

Enable binfmt + QEMU on the host first, then:

```bash
PLATFORM=linux/amd64,linux/arm/v7 ./scripts/build.sh buildx
```

## 🗂️ Repository layout

```
.
├── Dockerfile                 # FusionPBX image (on top of usyeimar/freeswitch)
├── entrypoint.sh              # Startup dashboard + DB wait, then supervisord
├── freeswitch/
│   ├── Dockerfile             # Base FreeSWITCH image build
│   └── start-freeswitch.sh    # FreeSWITCH startup script (DB wait + boot)
├── scripts/
│   ├── start.sh               # dev (follow logs) / prod (detached)
│   ├── stop.sh                # Stop the stack
│   ├── logs.sh                # Tail logs
│   ├── build.sh               # Build base / app / multi-arch
│   ├── shell.sh               # Shell into fusionpbx
│   ├── db-shell.sh            # psql into postgres
│   └── clean.sh               # Wipe everything (volumes incl.)
├── compose.yml                # Two-service stack (fusionpbx + postgres)
└── .env.example               # Environment template (copy to .env)
```

## ✅ TODO / What I'd improve next

- [ ] Minimize build by installing libraries to `/usr/local` instead of bulk copying
- [x] Move DB credentials to a `.env` file instead of `compose.yml`
- [ ] Add a health check for FreeSWITCH (currently only the container is checked)
- [ ] Publish stable tagged versions on Docker Hub instead of `:latest`
- [ ] CI workflow that builds + pushes the multi-arch images on each tag

## 🔗 References

- 🌐 [FusionPBX](https://www.fusionpbx.com/) · [Source & releases](https://github.com/fusionpbx/fusionpbx)
- ☎️ [FreeSWITCH](https://freeswitch.com/) — the underlying communication platform

> FusionPBX and FreeSWITCH are free software under their respective open-source licenses. This repository is an independent Dockerization built from their public sources.

## 👤 Author

**Yeimar Yecid Lemus Romaña** — [GitHub](https://github.com/usyeimar) · [LinkedIn](https://linkedin.com/in/usyeimar)
