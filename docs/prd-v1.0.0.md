# PRD: minerva-deploy v1.0.0

## Goal

Achieve the first successful, reproducible, GitOps-driven deploy to the Minerva server with all 15 services running — maximizing infrastructure-as-code to eliminate manual post-deploy configuration wherever possible.

v1.0.0 means: push to main, CI passes, Ansible deploys over SSH, and every service comes up configured and healthy without touching a UI.

---

## Scope

### Workstream 1 — Pre-deploy hardening

Resolve known security issues and hygiene gaps before the first deploy attempt. Items informed by external security review.

**Security — must fix before first deploy:**

- Scrub leaked credentials from git history (`compose/homepage/config/services.yaml:102-103` — email and password committed, even if commented) using BFG Repo-Cleaner; rotate the affected credential
- Scope filebrowser volume mount from `/:/srv` (full host filesystem RW) to a specific directory
- Remove `privileged: true` from cadvisor and glances — use minimal capabilities instead (`--device /dev/kmsg` for cadvisor; `SYS_PTRACE` + `DAC_READ_SEARCH` for glances)
- Bind services behind the reverse proxy to `127.0.0.1` instead of `0.0.0.0` — services like Grafana, Prometheus, Dozzle are currently directly accessible on the LAN, bypassing NPM auth and SSL
- Replace `host_key_checking = False` in `ansible.cfg` with `StrictHostKeyChecking=accept-new` (TOFU model)
- Add `permissions: { contents: read }` to CI workflow; SHA-pin high-risk third-party actions (`actions/checkout`, `actions/setup-python`)
- Fix SSH port change lockout — `ansible_port` is never set in `all.yml`, so changing `minerva_ssh_port` from 22 breaks the playbook mid-run when sshd restarts on the new port
  - *Decision:* Standardize SSH on port 22. Strip out custom `minerva_ssh_port` configuration. UFW and Tailscale will provide the security boundary.
- Integrate Tailscale for secure deploy access:
  - Add a new `tailscale` Ansible role (wrapping `artis3n/ansible-role-tailscale`)
  - Authenticate using a reusable `vault_tailscale_auth_key`
  - Allow UDP `41641` in UFW for Tailscale direct connections
- Evaluate Docker socket proxy for the 5 containers mounting `docker.sock` (Dozzle, Glances, Homepage, Komodo Periphery, Filebrowser via `/` mount)

**Hygiene:**

- Pin Docker image tags for all 13 unpinned services (only cadvisor and Komodo are currently pinned)
- Add `restart: unless-stopped` to all compose services (most currently have no restart policy — Docker default is `no`)
- Add healthchecks to the 11 services that lack them
- Fix compose-sync to notify restart handler on `compose.yml` changes (currently only `.env` changes trigger restarts)
- Fix or remove `minerva-wipe.sh` (references nonexistent `ansible/wipe.yml`)
- Make `minerva-setup.sh` idempotent or replace with a task runner
- Add `.github/dependabot.yml` (referenced in project docs, missing from repo)
- Review UFW port allowlist against actual service requirements
- Remove dead `ansible_become_password` from `all.yml` (bootstrap grants `NOPASSWD: ALL`, making it unused)
- Replace `ChallengeResponseAuthentication` with `KbdInteractiveAuthentication` in SSH hardening (old name deprecated in OpenSSH 8.7+, may be silently ignored on Ubuntu 24.04)
- Change `apt dist-upgrade` to `upgrade: safe` in the harden role for unattended deploys

### Workstream 2 — IaC maximization

Minimize manual UI configuration by templating service configs and provisioning through Ansible. `all.yml` becomes the single source of truth for all service-facing values.

#### High IaC potential — declarative config files

| Service | Mechanism | What to template |
|---------|-----------|-----------------|
| Grafana | Provisioning YAML + existing dashboard JSON | Datasource pointing to Prometheus, dashboard auto-loading from JSON files already in repo |
| Prometheus | `prometheus.yml` | Scrape targets (currently hardcoded hostnames and ports) |
| Homepage | `settings.yaml`, `services.yaml` | Service URLs, ports, and descriptions derived from `all.yml` |
| AdGuard Home | `AdGuardHome.yaml` | Initial DNS config, upstream servers, DNS rewrites — skip the first-run setup wizard |
| Glances | `glances.conf` | Already committed; template only if values need to vary by host |

#### Medium IaC potential — API or env-var driven

| Service | Mechanism | What to configure |
|---------|-----------|------------------|
| Nginx Proxy Manager | Ansible `uri` module against its API, or accept manual setup | Proxy hosts, SSL certs (Cloudflare DNS challenge) |
| Uptime Kuma | REST API via Ansible | Monitors for each service, status page layout |
| Komodo | Environment variables in `.env` | Core settings already managed via vault; stack/server config may require API |
| n8n | Environment variables in `.env` | Server settings only; workflows are user content and remain manual |

#### Low IaC potential — accept manual

| Service | Reason |
|---------|--------|
| Mealie | Recipes and meal plans are user data, not infrastructure |
| File Browser | Minimal config; mostly a file-access UI |
| ntfy | Topics are client-driven; server config is env-var only |
| Dozzle | Zero config — reads `docker.sock` |
| cAdvisor | Already configured via compose command flags |
| Node Exporter | Already configured via compose command flags |

#### Variable strategy

- Promote service ports, hostnames, and enabled/disabled flags to canonical variables in `all.yml`
- Jinja2 templates reference these variables to generate config files
- compose-sync role is extended to render templates before syncing (or uses `ansible.builtin.template` to render on target)
- Adding a new service follows a documented pattern: compose file → variables in `all.yml` → templates if applicable

### Workstream 3 — First deploy

Staged rollout with validation gates.

| Stage | Roles | Validate |
|-------|-------|----------|
| 1 | bootstrap + harden | SSH access works, users exist, UFW active, fail2ban running |
| 2 | geerlingguy.docker | `docker compose version` succeeds, Docker Engine running |
| 3 | compose-sync | Files present on server, `.env` files written with correct permissions, templated configs valid |
| 4 | compose-up | All 15 services report healthy via `docker compose ps` |

Each stage is validated before proceeding. If a stage fails, fix the issue before moving forward.

### Workstream 4 — GitOps pipeline

Continuous deployment via GitHub Actions.

- **New workflow:** `deploy.yml` triggers on push to `main` (after CI jobs pass)
- **Mechanism:** SSH from GitHub-hosted runner into Minerva, run `ansible-playbook ansible/playbook.yml`
  - *Decision:* Runner uses `tailscale/github-action@v2` with an ephemeral auth key to join the Tailscale network, SSHing into Minerva's stable Tailscale IP without exposing the server to the public internet.
- **Secrets needed:** `SSH_PRIVATE_KEY`, `VAULT_PASSWORD`, `MINERVA_IP`, `SSH_PORT` (plus Tailscale OAuth secrets)
- **Post-deploy:** Health check verifying all services respond (script or Ansible task)
- **Failure path:** Notification via ntfy or GitHub Actions built-in notification; no auto-rollback in v1.0.0

This approach (SSH from hosted runner) is chosen over a self-hosted runner because Ansible needs to manage OS-level state (users, packages, firewall rules), not just containers.

---

## Success criteria

1. **All services healthy:** `docker compose ps` across all 15 service directories shows containers running and healthy
2. **Idempotent:** Second `ansible-playbook` run reports zero changed tasks
3. **GitOps:** Merging a PR to `main` triggers CI → deploy automatically, with no manual SSH
4. **Reproducible:** A fresh deploy on a wiped Ubuntu 24.04 server reaches the same end state
5. **IaC:** Grafana datasources, Prometheus scrape targets, Homepage layout, and AdGuard DNS config are version-controlled and applied automatically — no manual UI setup for core functionality
6. **Single config file:** A new operator can configure their deployment by editing only `all.yml` and `vault.yml`
7. **Security baseline:** No leaked credentials in git history; no container has unnecessary privileges; services behind the reverse proxy are not directly accessible on the LAN; CI workflows follow least-privilege; all images pinned to specific versions

---

## Out of scope

- Multi-host deployment or clustering
- High availability or redundancy
- Backup and restore procedures
- Public internet exposure (LAN-only for v1.0.0)
- Komodo as a CD engine (stays as a management/monitoring UI)
- Migration from Docker Compose to Kubernetes or Swarm
- Prometheus alerting rules (alertmanager)
- Service-level user content (n8n workflows, Mealie recipes, File Browser data)
- SSL certificate management beyond what Nginx Proxy Manager provides
- External DNS configuration (managed outside this repo)
- Auto-rollback on failed deploys

---

## Constraints

- **Git history scrub required:** Leaked credentials in `services.yaml` require a history rewrite (BFG Repo-Cleaner); all forks and local clones must be re-cloned afterward
- **Single operator:** Bryan is the sole admin; all automation must be comprehensible and maintainable by one person
- **Hardware:** One bare-metal Ubuntu 24.04 server with a static LAN IP
- **Budget:** Homelab — no cloud spend, no paid CI runners
- **Branch protection:** GitHub rulesets prevent direct push to `main`; all changes go through PRs
- **SSH exposure:** The deploy workflow requires Minerva's SSH port to be reachable from GitHub-hosted runners (public internet), which has security implications for a hardened server
- **Service limitations:** Some services (Nginx Proxy Manager, Uptime Kuma) lack native declarative config; IaC for these requires API calls or documented manual steps
- **Testing ceiling:** Molecule tests run in Docker containers — UFW packet filtering, real systemd services, and full Docker-in-Docker are only testable on real hardware

---

## Open questions

1. **SSH exposure for deploys:** The harden role locks down SSH, but the deploy workflow needs to reach Minerva from a GitHub-hosted runner over the public internet. Options: expose SSH port via NAT with IP allowlisting (GitHub publishes runner IP ranges), VPN/tunnel (Tailscale, Cloudflare Tunnel), or accept the risk with key-only auth + fail2ban. Which approach?
   - *Resolved:* Use Tailscale. The GitHub Actions runner will ephemerally join the tailnet and deploy over the Tailscale IP. No public SSH exposure.

2. **SSH port mid-run lockout:** The harden role changes the SSH port and restarts sshd, but `ansible_port` is never updated — subsequent roles fail on the old port. Fix options: set `ansible_port: "{{ minerva_ssh_port }}"` in `all.yml` (simplest), use `meta: reset_connection` after the handler, or keep port at 22 and avoid the problem. The deploy workflow also needs to know the final port — hardcode, read from `all.yml`, or keep at 22?
   - *Resolved:* Keep port at 22. Strip out custom `minerva_ssh_port` and `harden_ssh_port` configuration. UFW will protect port 22 on the physical interface while NAT blocks it from the internet.

3. **NPM proxy host config:** Nginx Proxy Manager has no native declarative config. Its API is functional but unofficial. Is it worth automating proxy host creation via Ansible `uri` tasks, or should proxy hosts be a documented one-time manual setup?

4. **Image pinning format:** Pin to semver tags (e.g., `grafana/grafana:11.5.2` — readable, updatable via Dependabot) or SHA digests (e.g., `grafana/grafana@sha256:abc...` — most reproducible, harder to read)? How will updates be managed?

5. **Service health definition:** What constitutes "healthy" for services without built-in healthchecks? HTTP 200 on a known endpoint? Container running for >10 seconds? Specific log output?

6. **Rollback strategy:** If a deploy breaks a service, the v1.0.0 plan has no auto-rollback. Is "revert the PR and re-deploy" sufficient, or should there be a more structured rollback mechanism?

7. **Secrets rotation:** When a vault secret changes, should the pipeline re-deploy only affected services (smarter, more complex) or run the full playbook (simpler, slower)?

8. **Network segmentation:** UFW allows ports 22, 53, 80, 81, 443. Monitoring ports (9090, 4000, 61208, 3001, 9999) are exposed on the host but not firewalled. Should they be accessible only via reverse proxy, or is LAN-only access acceptable?

9. **Compose file templating:** Should `compose.yml` files become Jinja2 templates (for image tags, ports, environment values), or remain static with configurable values pulled from `.env` files?

10. **Wipe procedure:** Does a `wipe.yml` playbook need to exist for v1.0.0, or is server reprovisioning handled by re-imaging the OS and re-running the playbook?

11. **Docker socket proxy:** Five containers mount `docker.sock` (Dozzle, Glances, Homepage, Komodo Periphery, Filebrowser via `/`). A socket proxy like `tecnativa/docker-socket-proxy` restricts API access per container but adds operational complexity. Is this worth it for a LAN-only homelab, or is fixing the filebrowser `/` mount sufficient for v1.0.0?

12. **Docker network subnet conflicts:** Docker networks are created without explicit subnet config. Docker's default range (`172.17+.0.0/16`) could overlap with the LAN (`192.168.x.x`) — unlikely but not guaranteed. Should subnets be explicitly configured?
