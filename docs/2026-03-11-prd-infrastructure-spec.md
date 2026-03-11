# Product Requirements & Infrastructure Spec: Minerva Deploy v1.0.0

## 1. Project Overview & Goal
**Purpose:** Minerva Deploy is a GitOps-driven, single-command deployment for a complete, self-hosted homeserver stack. It provisions a fresh bare-metal Ubuntu 24.04 server via Ansible, delivering a hardened, monitored, and fully-configured environment orchestrated by Docker Compose.

**v1.0.0 Goal:** Achieve the first successful, reproducible, GitOps-driven deploy with all 15 services running. This means: push to `main`, CI passes, Ansible deploys over SSH via Tailscale, and every service comes up configured and healthy—maximizing Infrastructure-as-Code (IaC) to eliminate manual post-deploy UI configuration.

> **Bootstrap exception:** The *first* deploy requires a one-time manual step — run the playbook locally to install Tailscale on the server and retrieve its IP, then add `MINERVA_TAILSCALE_IP` to GitHub Secrets. All subsequent deploys are fully automated via push to `main`.

**Core Principles:**
- **GitOps-Driven:** Continuous deployment pipeline managed via GitHub Actions.
- **Infrastructure-as-Code (IaC):** Strict adherence to configuration via code; `all.yml` acts as the single source of truth.
- **Security First:** Robust baseline hardening and secret management through Ansible Vault.
- **Zero-Magic DevEx:** Standardized developer onboarding using native tooling (`pip`, `ansible-galaxy`) over brittle shell scripts.

## 2. Architectural Blueprint & Constraints
**Control Plane:**
- **Local Control:** Ansible runs in an isolated Python virtual environment (`.venv`).
- **CI/CD Control:** GitHub Actions runners dynamically join the Tailscale network using ephemeral auth keys to securely deploy to the internal server without exposing SSH to the public internet.
- **Secrets Management:** Ansible Vault encrypts sensitive data. Secrets are injected at deploy-time into `.env` files.

**Server Topology (Hardware Constraint: 1 Bare-Metal Ubuntu 24.04 Server):**
- **Security Boundary:** UFW default-deny firewall (exposing only essential ports: 22, 53, 80, 443). SSH is hardened (key-only, fail2ban).
- **User Model:** 
  - `operator`: Initial user with manual admin rights.
  - `ansible`: Service account with passwordless sudo for running deployment playbooks.
  - `minerva`: Unprivileged application user owning Docker Compose files at `/opt/minerva-deploy`.

**Container Orchestration (Docker Compose v2):**
- **Networking:** Dedicated Docker networks (`networking` for reverse proxies/DNS, `monitoring` for observability tools, `default` for isolated app-to-app communication).

## 3. Service Ecosystem
The platform manages a stack of 15 containerized services, logically categorized:
- **Networking & DNS:** *Nginx Proxy Manager* (Reverse proxy/SSL), *AdGuard Home* (DNS filtering).
- **Monitoring & Observability:** *Prometheus & Grafana* (Metrics), *cAdvisor & Node Exporter* (System stats), *Glances & Dozzle* (Real-time dashboards), *Uptime Kuma* (Status pages).
- **Applications:** *Komodo* (Container UI), *n8n* (Automation), *Mealie* (Recipes), *File Browser* (File access), *ntfy* (Push notifications), *Homepage* (Centralized dashboard).

## 4. Workstreams & Implementation Guardrails

### Workstream 1: Pre-Deploy Hardening (Security-First)
- **Scrub Secrets:** Remove leaked credentials from git history using BFG Repo-Cleaner.
- **Restrict Access:** Scope file mounts (e.g., Filebrowser to `/opt/minerva-deploy`) and drop `privileged: true` from containers (use `cap_add` or specific `devices`).
- **Network Isolation:** Internal services (Grafana, Prometheus) must bind to `127.0.0.1` instead of `0.0.0.0` to ensure access strictly through the reverse proxy.
- **Stability:** Strictly pin all active container images to explicit versions (semver).

### Workstream 2: GitOps Pipeline & DevEx
- **Strict Linting & Testing:** Enforce code quality via `ansible-lint`, `commitlint`, and end-to-end role testing using Molecule (Docker driver). All tasks must be idempotent.
- **Automated CD:** Merges to `main` trigger the GitHub Actions deploy workflow, executing the Ansible playbook over the Tailscale tunnel.
- **Zero-Magic Tooling:** Remove custom setup scripts (`minerva-setup.sh`); developers rely strictly on `requirements.txt` and `requirements.yml`.

## 5. Out of Scope for v1.0.0
- Multi-host deployment, clustering, or High Availability.
- Public internet exposure (LAN-only for v1.0.0).
- Auto-rollback on failed deploys.
- Full IaC Jinja2 templating of service configs (e.g., Grafana datasources, Prometheus targets, Homepage widgets, Uptime Kuma REST API setup are deferred to post-v1.0.0).
- Centralizing service ports, hostnames, and flags as Ansible variables in `all.yml` (deferred alongside Jinja2 templating — no value until templating is in scope).
- Implementation of a Docker socket proxy.