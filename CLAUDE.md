# Minerva Deploy - Project Context

## Stack
- Ansible + Molecule (Docker driver) for TDD
- Docker Compose for services
- Target: Ubuntu 24.04 server (bare metal, static LAN IP)
- Dev: macOS M4, Python 3.11 venv at `.venv/`

## Pipeline
bootstrap → harden → geerlingguy.docker → compose-sync → compose-up

## Three-user model
- bryan: initial/operator user
- ansible: service account (passwordless sudo)
- minerva: app user (owns /opt/minerva-deploy)

## Role status
- bootstrap: complete, molecule tests passing
- harden: complete, molecule tests passing
- geerlingguy.docker: external role, installed via ansible-galaxy
- compose-sync: complete, molecule tests passing — syncs configs and writes .env secrets
- compose-up: scaffolded — creates docker networks, runs docker compose up

## CI
- `.github/workflows/ci.yml`: ansible-lint + molecule matrix (bootstrap, harden)
- `.github/workflows/commitlint.yml`: enforces conventional commits on push/PR
- Vault password written to `.vault_pass` from `secrets.VAULT_PASSWORD`
- ansible-lint passing

## Configuration
- `ansible/group_vars/all/all.yml`: single user-facing config file
  - Canonical vars: `minerva_ip`, `minerva_domain`, `minerva_timezone`, `compose_username`
  - Role vars derived from canonical vars (do not edit directly)
  - `compose_sync_secrets`: per-service .env content, referencing vault vars
  - `compose_up_services`: auto-started; `compose_up_manual_services`: synced but not started
- `ansible/group_vars/all/vault.SAMPLE.yml`: template for creating encrypted `vault.yml`
- `ansible/inventory`: holds host group `[minerva]`; IP set via `minerva_ip` in all.yml

## Variable naming convention
Role variables are prefixed with the role name:
- bootstrap_deploy_user, bootstrap_minerva_user, bootstrap_minerva_group
- harden_ssh_port, harden_minerva_user
- compose_sync_base_dir, compose_sync_owner, compose_sync_group, compose_sync_secrets
- compose_up_base_dir, compose_up_services, compose_up_docker_networks

## Secrets pattern
- Secrets live in vault-encrypted `ansible/group_vars/all/vault.yml` (gitignored)
- `all.yml` references them as `{{ vault_* }}` within `compose_sync_secrets`
- compose-sync role writes them as `.env` files on the server at deploy time
- `compose/**/.env` is gitignored — never committed

## Next steps
1. compose-up molecule tests — last untested role
2. Delete local plaintext `.env` files (`compose/mealie/.env`, `compose/n8n/.env`, `compose/komodo/.env`) — compose-sync will own them
3. Populate `ansible/group_vars/all/vault.yml` from `vault.SAMPLE.yml` with real secrets
4. First deploy: run playbook against Minerva in stages (bootstrap+harden first, then full)
5. Add compose-sync to CI molecule matrix in `.github/workflows/ci.yml`
6. `scripts/minerva-setup.sh` — not idempotent, not tested; absorb into a role (bootstrap or local_env), demote script to thin wrapper or remove
7. `.vscode/` in repo root — editor config shouldn't be in a GitOps repo; gitignore it or replace with `.editorconfig`
8. `:latest` image tags in compose files — reproducibility risk; pin to specific versions (11 services affected)
9. `harden` role gaps — UFW rules (allow only used ports) and fail2ban/sshguard not yet implemented; add molecule tests asserting UFW active and SSH locked down

## Deleted / deprecated
- system-init, container-init: removed, replaced by role pipeline above
- ansible/docker-up.yml, ansible/wipe.yml, ansible/list.yml: deleted
- scripts/minerva-alias.sh, minerva-playbook.sh, minerva-docker-up.sh, minerva-help.sh: deleted
