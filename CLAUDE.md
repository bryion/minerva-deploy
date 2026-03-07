# Minerva Deploy - Project Context

## Stack
- Ansible + Molecule (Docker driver) for TDD
- Docker Compose for services
- Target: Ubuntu 24.04 server at 192.168.1.19
- Dev: macOS M4, Python 3.11 venv

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
- compose-sync: scaffolded — syncs configs, .env secrets, base directory
- compose-up: scaffolded — creates docker networks, runs docker compose up

## CI
- `.github/workflows/ci.yml`: lint (ansible-lint) + molecule matrix (bootstrap, harden)
- Vault password written to `.vault_pass` from `secrets.VAULT_PASSWORD`
- ansible-lint passing

## Variable naming convention
Role variables are prefixed with the role name:
- bootstrap_deploy_user, bootstrap_minerva_user, bootstrap_minerva_group
- harden_ssh_port, harden_minerva_user
- compose_up_base_dir, compose_up_services, compose_up_docker_networks

## Deleted / deprecated
- system-init, container-init: removed, replaced by role pipeline above
- ansible/docker-up.yml, ansible/wipe.yml, ansible/list.yml: deleted
- scripts/minerva-alias.sh, minerva-playbook.sh, minerva-docker-up.sh, minerva-help.sh: deleted
