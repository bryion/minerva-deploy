# Changelog

All notable changes to this project will be documented in this file.
## [Unreleased]

### Bug Fixes

- Correct YAML syntax in harden-ssh.yml

- Remove unnecessary MCP server setting from VSCode configuration

- Change homepage service restart policy to 'unless-stopped'

- Update volume paths in Docker Compose for homepage service

- Remove trailing newline at the end of main.yml

- Update volume path in Docker Compose for Grafana service to use relative path

- Update volume path in Docker Compose for Grafana service to use named volume; change script permissions for execution

- Update Grafana service volume path in Docker Compose to use named volume

- Add healthcheck configuration for nginx-proxy-manager service in Docker Compose

- Update volume paths in Docker Compose for homepage service to use absolute paths

- Add base URL configuration to homepage settings

- Update HOMEPAGE_ALLOWED_HOSTS to include additional allowed hosts

- Update HOMEPAGE_ALLOWED_HOSTS to include home.nlab.casa

- Correct service names and paths in Docker Compose files

- Remove version specification from Docker Compose for it-tools service

- Remove tmpfs configuration and adjust privileges in glances Docker Compose

- Update glances Docker Compose configuration and remove it-tools service

- Update healthcheck URL in ntfy Docker Compose configuration

- Add N8N_PROTOCOL environment variable in n8n Docker Compose configuration

- Add N8N_HOST and NODE_ENV environment variables in n8n Docker Compose configuration

- **playbook:** Add compose-up role to pipeline

- **config:** Correct n8n env vars for nginx-proxy-manager setup


### CI/CD

- Add GitHub Actions workflow for lint and molecule tests

- Update github actions workflow and ansible playbook

- Add ansible-lint config, fix role violations

- Add commitlint workflow to enforce conventional commits

- **changelog:** Add git-cliff config and GitHub workflow for auto-generated changelogs

- Add compose-up to molecule matrix and enable Dependabot


### Documentation

- Add CLAUDE.md project context

- **config:** Add comments to komodo env vars, fix minerva_timezone self-reference

- **claude:** Update project context to reflect current state

- **claude:** Add next steps and tech debt items

- **claude:** Add harden gaps and tech debt to next steps

- **readme:** Rewrite for clarity, lead with end product and prerequisites


### Features

- Enhance setup script with virtual environment creation and alias setup; add playbook runner script

- Refactor system initialization tasks and add Docker compose configurations

- Update Docker Compose configurations for Grafana and Homepage services

- Add mealie and n8n services with Docker Compose configurations

- Update deployment tasks to use dynamic git destination variable

- Add Docker Up playbook and corresponding script with logging

- Add Docker Compose configuration for it-tools service

- **bootstrap:** Add role with molecule tests - creates ansible and minerva users

- **bootstrap:** Add role with molecule tests

- **harden:** Add role with molecule tests - SSH hardening, updates, hushlogin

- **compose-sync:** Implement role with molecule tests passing

- **config:** Add komodo and n8n env vars to compose_sync_secrets


### Miscellaneous

- Update setup script and Ansible inventory structure; enhance SSH hardening tasks

- Streamline deployment tasks by removing git cloning and ensuring directory structure

- Add requirements.txt for reproducible venv

- Track .envrc and requirements.txt, fix .gitignore

- Remove deprecated roles and Vagrantfile

- Remove empty list.yml and deprecated docker-up.yml

- Remove wipe.yml

- Clean up .gitignore — remove duplicates, add compose .env entries

- **inventory:** Make server IP configurable via minerva_ip in all.yml

- **config:** Use neutral default IP 192.168.1.100

- Rename docker-compose.yml to compose.yml across all services

- Remove dead kubernetes.yaml stub from homepage config

- **gitignore:** Exclude compose runtime data dirs, keep .gitkeeps

- Harden molecule tests, untrack .vscode, add compose-sync to CI

- **changelog:** Update CHANGELOG.md [skip ci]


### Add

- Healthcheck dozzle, config files for homepage


### Start

- Foundation of repo structure starting with ansible



