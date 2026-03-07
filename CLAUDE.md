# Minerva Deploy - Project Context

## Stack
- Ansible + Molecule (Docker driver) for TDI
- Docker Compose for services
- Target: Ubuntu 24.04 server at 192.168.1.19
- Dev: macOS M4, Python 3.11 venv

## Pipeline
bootstrap → harden → geerlingguy.docker → compose-sync → compose-up

## Three-user model
- bryan: initial/operator user
- ansible: service account (passwordless sudo)
- minerva: app user (owns /opt/minerva-deploy)

## Current state
- bootstrap role: complete, molecule tests passing
- harden role: complete, molecule tests passing
- CI: .github/workflows/ci.yml added, failing on playbook.yml referencing deleted role system-init
- compose-sync, compose-up: scaffolded, not implemented

## Immediate next task
Fix ansible/playbook.yml - remove system-init reference, update to new role pipeline
