# Minerva Deploy

Minerva is a self-hosted homeserver stack running on a bare-metal Ubuntu 24.04 machine on your LAN. This repo provisions the server from scratch and keeps it in sync — security hardening, Docker engine, and all services — using Ansible and Docker Compose.

**Deployed services:** AdGuard Home, Caddy (via Nginx Proxy Manager), Mealie, n8n, Komodo, Grafana + Prometheus + cAdvisor + Node Exporter, Dozzle, Glances, File Browser, Uptime Kuma, ntfy, Homepage.

---

## Prerequisites

### Target server
- Fresh **Ubuntu 24.04** install (bare metal or VM)
- SSH public key installed for an initial sudo user
- Static LAN IP assigned

### Local machine (control node)
- macOS or Linux
- **Git**
- **Python 3.11+**
- **Docker** (for running Molecule tests locally)

---

## Setup

### 1. Clone the repo

```bash
git clone https://github.com/bryion/minerva-deploy.git
cd minerva-deploy
```

### 2. Create the Python environment

```bash
bash scripts/minerva-setup.sh
```

This creates `.venv/`, installs Ansible and dependencies, and installs required Ansible collections.

### 3. Activate the environment

Run this every time you open a new terminal:

```bash
source .venv/bin/activate
```

You'll see `(.venv)` in your prompt when it's active.

### 4. Configure

Edit `ansible/group_vars/all/all.yml` — this is the single config file. Set your server IP, domain, timezone, and which services to auto-start.

Copy `ansible/group_vars/all/vault.SAMPLE.yml` to `vault.yml`, fill in secrets, then encrypt it:

```bash
ansible-vault encrypt ansible/group_vars/all/vault.yml
```

### 5. Verify connectivity

```bash
ansible minerva -m ping
```

Expected: `minerva | SUCCESS => { ... "ping": "pong" }`

---

## Deployment

Run the full playbook:

```bash
ansible-playbook ansible/playbook.yml
```

The pipeline runs in order: **bootstrap → harden → docker → compose-sync → compose-up**

To run only specific stages use tags or limit to roles as needed.

---

## Architecture

| Layer | Tool |
|---|---|
| Config management | Ansible Core (local `.venv`) |
| Service orchestration | Docker Compose |
| Testing | Molecule (Docker driver) |
| Secrets | Ansible Vault → `.env` files at runtime |

**Three-user model on the server:**
- `bryan` — your operator account (initial SSH login)
- `ansible` — service account with passwordless sudo (created by bootstrap)
- `minerva` — app user that owns `/opt/minerva-deploy` (no sudo)

---

## Testing

```bash
# Test a single role
cd ansible/roles/bootstrap && molecule test

# Lint
ansible-lint
```

CI runs ansible-lint and Molecule on every push (see `.github/workflows/`).
