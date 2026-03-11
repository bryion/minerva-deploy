# Infrastructure Specification: Minerva Deploy v1.0.0

## 1. Project Overview & Vision
**Purpose:** Minerva Deploy provides a single-command deployment for a complete, self-hosted homeserver stack. The system provisions a fresh bare-metal Ubuntu 24.04 server via Ansible, delivering a hardened, monitored, and fully-configured environment orchestrated by Docker Compose.

**Core Principles:**
- **GitOps-Driven:** Continuous deployment pipeline managed via GitHub Actions.
- **Infrastructure-as-Code (IaC):** Strict adherence to configuration via code, eliminating manual post-deploy UI configuration.
- **Security First:** Robust baseline hardening and secret management through Ansible Vault.
- **Reproducibility:** A single YAML configuration (`all.yml`) acting as the source of truth for the entire deployment.

## 2. Architectural Blueprint
**Control Plane:**
- **Local Control:** Ansible runs in an isolated Python virtual environment (`.venv`).
- **CI/CD Control:** GitHub Actions runners dynamically join the Tailscale network using ephemeral auth keys to securely deploy to the internal server without exposing SSH to the public internet.
- **Secrets Management:** Ansible Vault encrypts sensitive data (passwords, tokens). Secrets are injected at deploy-time into `.env` files or directly into Ansible role executions.

**Server Topology:**
- **Target OS:** Ubuntu 24.04 (Bare Metal/VM) with a static IP.
- **Security Boundary:** 
  - UFW default-deny firewall configured to expose only essential ports (SSH, DNS, HTTP/HTTPS).
  - SSH hardened (key-only authentication, port 22, fail2ban monitoring).
- **User Model:** 
  - `operator`: Initial user with manual admin rights.
  - `ansible`: Service account with passwordless sudo specifically for running deployment playbooks.
  - `minerva`: Unprivileged application user that owns all Docker Compose files and mounted data at `/opt/minerva-deploy`.

**Container Orchestration:**
- **Engine:** Docker Engine with Docker Compose v2.
- **Networking:** Dedicated Docker networks (`networking` for reverse proxies/DNS, `monitoring` for observability tools, `default` for isolated app-to-app communication).

## 3. Service Ecosystem (High Level)
The platform manages a stack of over 15 distinct containerized services, logically categorized into three primary domains:

- **Networking & DNS:**
  - *Nginx Proxy Manager:* Handles reverse proxy routing and automatic SSL termination.
  - *AdGuard Home:* Provides network-wide DNS filtering and ad blocking.
- **Monitoring & Observability:**
  - *Prometheus & Grafana:* Core metrics aggregation and visual dashboards.
  - *cAdvisor & Node Exporter:* Gathers per-container and host-level system metrics.
  - *Glances & Dozzle:* Real-time dashboards for system resources and container logs.
  - *Uptime Kuma:* Active uptime monitoring and status pages.
- **Applications:**
  - *Komodo:* Lightweight container and service orchestration interface.
  - *n8n:* Workflow and process automation.
  - *Mealie, File Browser, ntfy, Homepage:* Core user-facing services for recipe management, file access, push notifications, and a centralized entry dashboard.

## 4. Implementation Methodologies & Guardrails
**Security-First Approach:**
- Internal services (e.g., Grafana, Prometheus) must bind to `127.0.0.1` instead of `0.0.0.0` to ensure they are accessed securely through the reverse proxy.
- All Docker images must be strictly pinned to explicit tags (semver preferred) to prevent regressions.
- Containers run with minimum necessary privileges (dropping `privileged: true` in favor of specific `cap_add` or `devices` declarations, applying `read_only: true` with `tmpfs`, and using `no-new-privileges`).

**Infrastructure-as-Code (IaC) Maximization:**
- All variables (ports, hostnames, configuration flags) are centralized in `ansible/group_vars/all/all.yml`.
- Configuration files for services (like Grafana datasources, Prometheus scrape targets, Homepage widgets) are generated using Jinja2 templates via Ansible, bypassing native UI setup wizards.

**CI/CD & GitOps:**
- Code changes require PR reviews. GitHub Actions CI pipeline enforces linting (`commitlint`, `ansible-lint`) and performs end-to-end testing of Ansible roles using Molecule.
- Merges to `main` trigger the CD workflow, executing the Ansible playbook over the Tailscale tunnel.

**Idempotency & Testing:**
- All Ansible tasks must be strictly idempotent, guaranteeing zero changes on repeated runs.
- Extensive test coverage using Molecule (with the Docker driver) ensures the roles function correctly across fresh and existing states.

## 5. Roadmap & Evolutionary Goals
**Immediate v1.0.0 Goals:**
- Remediate all critical and high security findings (scrub leaked credentials, restrict file mounts, drop excessive privileges).
- Pin all active container images.
- Finalize the automated GitOps deployment pipeline using Tailscale.
- Enhance IaC coverage by templating remaining hardcoded configurations.
- Ensure the full `ansible-playbook` run leaves the server in a 100% operational and healthy state.
