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

A turnkey container image for **FusionPBX**, the open-source multi-tenant PBX system, built on top of a custom **FreeSWITCH** base image. The whole stack (PBX app + database) comes up with `make up`, ready to receive SIP traffic and serve the FusionPBX web UI.

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
- 🛠️ `make` (optional but recommended)

### Run

```bash
git clone https://github.com/usyeimar/fusion-pbx.git
cd fusion-pbx
make up
```

### Access the UI

- 🌐 HTTP: http://localhost:8080
- 🔒 HTTPS: https://localhost:8443

The first time, FusionPBX will walk you through its install wizard. Point it at the bundled Postgres (see DB config below).

## 🛠️ Common commands

```bash
make up         # Start stack (background)
make down       # Stop and remove stack
make restart    # Restart all services
make logs       # Tail logs from all containers
make build      # Build images
make rebuild    # Build with --no-cache
make app-shell  # bash into the fusionpbx container
make db-shell   # psql into postgres
make ps         # List running containers
make init       # First-time helper (pull + up + ps)
make clean      # Stop and wipe volumes (⚠️ destroys DB)
```

For multi-arch builds:
```bash
PLATFORM=linux/arm/v7 make fusionpbx-buildx
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

## 🔐 Default database config

| Setting | Value |
| --- | --- |
| Host | `postgres` |
| Database | `fusionpbx` |
| User | `fusionpbx` |
| Password | Set in `compose.yml` (rotate before deploying anywhere real) |

> ⚠️ **Security note:** The default password committed in `compose.yml` is for local testing only. Move it to a `.env` file (and add `.env` to `.gitignore`) before exposing this stack to anything outside your machine.

## 🧱 Devices and RTP

- Serial devices exposed to the container: `/dev/ttyUSB2`, `/dev/ttyUSB3`
- RTP UDP range: `16384–16390` (matches the FreeSWITCH config baked into the image)

If you don't have these serial devices, remove them from `compose.yml` — they're meant for GSM/PSTN gateways.

## 🧭 Multi-arch builds

Pre-tested on x86_64 and armv7. To build for other platforms:

- 📖 [Docker Buildx docs](https://docs.docker.com/buildx/working-with-buildx/)
- 🐳 [docker/buildx project](https://github.com/docker/buildx/)
- 🦾 [Arm on Linux tutorial](https://community.arm.com/developer/tools-software/tools/b/tools-software-ides-blog/posts/getting-started-with-docker-for-arm-on-linux)
- 💻 [QEMU downloads](https://www.qemu.org/download/)

Enable binfmt + QEMU on the host first, then:

```bash
PLATFORM=linux/amd64,linux/arm/v7 make fusionpbx-buildx
```

## 🗂️ Repository layout

```
.
├── Dockerfile                 # FusionPBX image (on top of usyeimar/freeswitch)
├── freeswitch/
│   ├── Dockerfile             # Base FreeSWITCH image build
│   └── start-freeswitch.sh    # FreeSWITCH startup script
├── config/
│   └── supervisord.conf       # nginx + php-fpm + freeswitch under supervisord
├── compose.yml                # Two-service stack (fusionpbx + postgres)
├── Makefile                   # Common operations
├── start-freeswitch.sh        # DB-wait + FreeSWITCH boot
└── docker.rule                # iptables/Docker firewall ruleset
```

## ✅ TODO / What I'd improve next

- [ ] Minimize build by installing libraries to `/usr/local` instead of bulk copying
- [ ] Move DB credentials to a `.env` file (or Docker secrets) instead of `compose.yml`
- [ ] Add a health check for FreeSWITCH (currently only the container is checked)
- [ ] Publish stable tagged versions on Docker Hub instead of `:latest`
- [ ] CI workflow that builds + pushes the multi-arch images on each tag

## 👤 Author

**Yeimar Yecid Lemus Romaña** — [GitHub](https://github.com/usyeimar) · [LinkedIn](https://linkedin.com/in/usyeimar)
