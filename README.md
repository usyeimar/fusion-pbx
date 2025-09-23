## 📦 Fusion PBX

Dockerized FusionPBX (x86_64 and armv7 tested).

FusionPBX is a powerful, open-source, multi-tenant PBX system with a modern web interface. It supports multiple domains, robust call routing, voicemail, IVR, conferencing, call center features, faxing, phone provisioning, and more—all manageable from an intuitive dashboard.

### ✨ Highlights
- 🧱 Slimmer images (separate build/runtime stages)
- 🛠️ Build deps from git (no private repos)
 - 🏢 Multi-tenant domains, extensions, and routing
 - ☎️ Call queues, ring groups, conferences, IVR, voicemail-to-email
 - 📨 Fax-to-email and inbound/outbound faxing
 - 🧩 Phone provisioning and device management

### 🚀 Quickstart
1. 🧰 Install Docker and Docker Compose plugin
2. 🔧 Configure `compose.yml` if needed (ports, devices, volumes)
3. ▶️ Start stack:
   ```bash
   make up
   ```
4. 🌐 Access UI:
   - HTTP: `http://localhost:8080`
   - HTTPS: `https://localhost:8443`

### 🧪 Useful Commands
- ▶️ Start: `make up`
- ⏹️ Stop: `make down`
- 🔁 Restart: `make restart`
- 🧾 Logs: `make logs`
- 🧱 Build: `make build` | ♻️ Rebuild: `make rebuild`
- 🐚 Shell app: `make app-shell` | 🐘 DB: `make db-shell`

### 🧩 Services (from `compose.yml`)
- `fusionpbx`: Web UI and application
- `postgres`: Database

### 🔐 Default DB (env)
- Host: `postgres`
- DB: `fusionpbx`
- User: `fusionpbx`
- Pass: set in `compose.yml`

### 🧱 Devices and RTP
- Serial devices exposed: `/dev/ttyUSB2`, `/dev/ttyUSB3`
- RTP UDP range: `16384-16390`

### 🧭 Multi-arch builds (optional)
- Read Docker Buildx docs: [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/)
- Enable binfmt and QEMU on your system
- Buildx project: [docker/buildx](https://github.com/docker/buildx/)
- ARM on Linux guide: [Arm community tutorial](https://community.arm.com/developer/tools-software/tools/b/tools-software-ides-blog/posts/getting-started-with-docker-for-arm-on-linux)
- QEMU downloads: [qemu.org](https://www.qemu.org/download/)

### ✅ TODO
- [ ] Minimize build by installing libraries to `/usr/local` instead of bulk copying
