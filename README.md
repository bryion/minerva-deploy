<p align="center">
  <img src="media/n-up-green/n-cap-green-x256.png" alt="Minerva" width="128">
</p>

<h1 align="center">Minerva Deploy</h1>

<p align="center">
  A self-hosted homeserver stack on bare-metal Ubuntu 24.04.<br>
  Provisioned from scratch with Ansible. Orchestrated with Docker Compose.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Ubuntu-24.04-E95420?logo=ubuntu&logoColor=white" alt="Ubuntu 24.04">
  <img src="https://img.shields.io/badge/Ansible-8+-EE0000?logo=ansible&logoColor=white" alt="Ansible 8+">
  <img src="https://img.shields.io/badge/Docker_Compose-v2-2496ED?logo=docker&logoColor=white" alt="Docker Compose">
</p>

---

## What is Minerva?

Minerva is a single-command deployment for a complete homeserver. One `ansible-playbook` run takes a fresh Ubuntu machine and delivers a hardened, monitored, fully-configured server running 15 services — with DNS filtering, reverse proxy, workflow automation, recipe management, container orchestration, and a full observability stack.

Everything is configured from a single YAML file. Secrets are vault-encrypted and injected at deploy time. Every role is tested with Molecule.

---

## Services

### Networking & DNS

| Service | Description | Port |
|---------|-------------|------|
| [Nginx Proxy Manager](https://nginxproxymanager.com/) | Reverse proxy with automatic SSL via Let's Encrypt (Cloudflare DNS challenge) | 80, 443, 81 (admin) |
| [AdGuard Home](https://adguard.com/adguard-home.html) | Network-wide DNS filtering and ad blocking | 53, 8181 (admin) |

### Monitoring & Observability

| Service | Description | Port |
|---------|-------------|------|
| [Grafana](https://grafana.com/) | Metrics dashboards and visualization | 4000 |
| [Prometheus](https://prometheus.io/) | Time-series metrics collection (scrapes node-exporter + cAdvisor) | 9090 |
| [cAdvisor](https://github.com/google/cadvisor) | Per-container resource usage metrics | 8082 |
| [Node Exporter](https://github.com/prometheus/node_exporter) | Host-level system metrics (CPU, memory, disk, network) | 9100 (host) |
| [Glances](https://nicolargo.github.io/glances/) | Real-time system monitoring dashboard | 61208 (host) |
| [Uptime Kuma](https://uptime.kuma.pet/) | Uptime monitoring and status page | 3001 |
| [Dozzle](https://dozzle.dev/) | Real-time Docker container log viewer | 9999 |

### Applications

| Service | Description | Port |
|---------|-------------|------|
| [Komodo](https://komo.do/) | Container and service orchestration platform (with MongoDB + Periphery agent) | 9120 |
| [n8n](https://n8n.io/) | Workflow automation | 5678 |
| [Mealie](https://mealie.io/) | Recipe management and meal planning | 9925 |
| [Homepage](https://gethomepage.dev/) | Dashboard with service integration | 3002 |
| [File Browser](https://filebrowser.org/) | Web-based file manager | 8383 |
| [ntfy](https://ntfy.sh/) | Push notification server | 2222 |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Control Node (your machine)                                │
│  Ansible + Molecule + Vault                                 │
└────────────────────────┬────────────────────────────────────┘
                         │ SSH
┌────────────────────────▼────────────────────────────────────┐
│  Minerva (Ubuntu 24.04)                                     │
│                                                             │
│  ┌─────────┐  ┌────────┐  ┌──────────┐  ┌───────────────┐  │
│  │ UFW     │  │ SSH    │  │ fail2ban │  │ Docker Engine │  │
│  │ firewall│  │ hardened│  │ SSH jail │  │ + Compose v2  │  │
│  └─────────┘  └────────┘  └──────────┘  └───────┬───────┘  │
│                                                  │          │
│  ┌───────────────────────────────────────────────▼───────┐  │
│  │  Docker Networks                                      │  │
│  │                                                       │  │
│  │  networking ─── NPM ◄──── internet                    │  │
│  │              └─ AdGuard                               │  │
│  │                                                       │  │
│  │  monitoring ──── Prometheus ◄── Node Exporter         │  │
│  │               ├─ Grafana    ◄── cAdvisor              │  │
│  │               └─ Glances                              │  │
│  │                                                       │  │
│  │  default ─── Komodo (Core + Mongo + Periphery)        │  │
│  │           ├─ n8n, Mealie, Homepage, Dozzle            │  │
│  │           ├─ Uptime Kuma, File Browser, ntfy          │  │
│  │           └─ ...                                      │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
│  Users: bryan (operator) │ ansible (sudo) │ minerva (app)   │
│  Data:  /opt/minerva-deploy/compose/                        │
└─────────────────────────────────────────────────────────────┘
```

### Provisioning pipeline

The playbook runs five roles in order:

| Stage | Role | What it does |
|-------|------|-------------|
| 1 | **bootstrap** | Creates `ansible` (service account, passwordless sudo) and `minerva` (app user, owns `/opt/minerva-deploy`) |
| 2 | **harden** | SSH hardening (key-only, custom port), UFW firewall (deny-all + allowlist), fail2ban (SSH jail), system updates |
| 3 | **geerlingguy.docker** | Installs Docker Engine, CLI, Compose plugin, enables on boot |
| 4 | **compose-sync** | Syncs compose files to server, writes vault-encrypted secrets as `.env` files |
| 5 | **compose-up** | Creates Docker networks (`monitoring`, `networking`), runs `docker compose up` per service |

### Security model

| User | Role | Sudo |
|------|------|------|
| `bryan` | Operator — initial SSH login, manual admin | Full sudo |
| `ansible` | Service account — runs playbooks | Passwordless sudo |
| `minerva` | App user — owns all compose files and data | None |

- **SSH:** Key-only auth, root login disabled, configurable port
- **Firewall:** UFW defaults deny-incoming, allows only service ports (SSH, DNS, HTTP/S, NPM admin)
- **Intrusion prevention:** fail2ban monitors SSH (5 retries, 1h ban)
- **Secrets:** Ansible Vault encrypts credentials, injected as `.env` at deploy time (never committed)

### Stack

| Layer | Tool |
|-------|------|
| Config management | Ansible 8+ (local `.venv`) |
| Service orchestration | Docker Compose v2 |
| Testing | Molecule (Docker driver) |
| Secrets | Ansible Vault → `.env` files at runtime |
| CI | GitHub Actions (commitlint + ansible-lint + Molecule matrix) |

---

## Getting started

### Prerequisites

**Target server:**
- Fresh Ubuntu 24.04 (bare metal or VM)
- SSH public key installed for an initial sudo user
- Static LAN IP (DHCP reservation recommended)

**Control node (your machine):**
- macOS or Linux
- Python 3.11+
- Docker (for Molecule tests)

### 1. Clone and set up

```bash
git clone https://github.com/bryion/minerva-deploy.git
cd minerva-deploy
bash scripts/minerva-setup.sh
source .venv/bin/activate
```

### 2. Configure

Edit `ansible/group_vars/all/all.yml` — the single config file for your deployment:

```yaml
minerva_ip: 192.168.1.100       # Your server's static IP
minerva_domain: example.com      # Base domain for reverse proxy
minerva_timezone: America/Los_Angeles
minerva_ssh_port: 22             # SSH port after hardening
compose_username: admin           # Default admin user across services
```

### 3. Set up secrets

```bash
cp ansible/group_vars/all/vault.SAMPLE.yml ansible/group_vars/all/vault.yml
# Fill in your secrets, then encrypt:
ansible-vault encrypt ansible/group_vars/all/vault.yml
```

### 4. Deploy

```bash
# Verify connectivity first
ansible minerva -m ping

# Run the full playbook
ansible-playbook ansible/playbook.yml
```

---

## Testing

Every custom role has Molecule tests using the Docker driver:

```bash
# Test a single role
cd ansible/roles/harden && molecule test

# Lint the full playbook
ansible-lint ansible/playbook.yml
```

CI runs commitlint, ansible-lint, and Molecule tests for all four roles on every push and pull request.

---

## Project structure

```
minerva-deploy/
├── ansible/
│   ├── playbook.yml                    # Main entrypoint
│   ├── inventory                       # Host definition
│   ├── group_vars/all/
│   │   ├── all.yml                     # Single config file
│   │   ├── vault.yml                   # Encrypted secrets (gitignored)
│   │   └── vault.SAMPLE.yml           # Secrets template
│   └── roles/
│       ├── bootstrap/                  # User + account setup
│       ├── harden/                     # SSH, UFW, fail2ban, updates
│       ├── geerlingguy.docker/         # Docker Engine (external)
│       ├── compose-sync/               # File sync + .env secrets
│       └── compose-up/                 # Network creation + service start
├── compose/                            # Per-service Docker Compose files
│   ├── adguardhome/
│   ├── nginx-proxy-manager/
│   ├── komodo/
│   ├── grafana/
│   ├── prometheus/
│   └── ... (15 services)
├── scripts/
│   ├── minerva-setup.sh               # Local environment bootstrap
│   └── minerva-wipe.sh                # Destructive Docker reset
└── .github/workflows/
    ├── ci.yml                          # Lint + Molecule matrix
    └── changelog.yml                   # Auto-generated changelog
```

---

## Roadmap

- [x] Ansible roles: bootstrap, harden, compose-sync, compose-up
- [x] Molecule tests for all custom roles
- [x] CI pipeline (commitlint + ansible-lint + Molecule)
- [x] Vault-encrypted secrets with `.env` injection
- [x] UFW firewall with configurable port allowlist
- [x] fail2ban SSH jail
- [ ] First deploy to production
- [ ] Pin all Docker images to specific versions (10 services on `:latest`)
- [ ] Absorb `minerva-setup.sh` into an Ansible role

---

## License

MIT
