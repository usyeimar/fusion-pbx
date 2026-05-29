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

A turnkey container image for **FusionPBX**, the open-source multi-tenant PBX system, built on top of a custom **FreeSWITCH** base image. The whole stack (PBX app + database) comes up with `./scripts/start.sh`, ready to receive SIP traffic and serve the FusionPBX web UI.

**Why custom images instead of the official ones?**

- 🧱 **Slimmer images** — separate build/runtime stages
- 🛠️ **Build dependencies pulled from git** (no private repos required)
- 🌍 **Multi-arch ready** — x86_64 + armv7 tested, ARM via Buildx
- ⚙️ **Sensible defaults** — RTP port range, supervisor config, nginx vhost are all pre-wired

## ✨ FusionPBX features (out of the box)

- 🏢 Multi-tenant domains, extensions, and routing
- ☎️ Call queues, ring groups, conferences, IVR, voicemail-to-email
- 📨 Fax-to-email and inbound/outbound faxing
- 🧩 Phone provisioning and device management
- 🌐 Modern web dashboard for the entire stack

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

The first time, FusionPBX will walk you through its install wizard. Point it at the bundled Postgres (see DB config below).

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

> ⚠️ **Security note:** `.env` is git-ignored. Set a strong `DB_PASS` before exposing this stack to anything outside your machine.

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

## 👤 Author

**Yeimar Yecid Lemus Romaña** — [GitHub](https://github.com/usyeimar) · [LinkedIn](https://linkedin.com/in/usyeimar)
