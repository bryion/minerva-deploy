# Changelog
### Unreleased

- Merge v1.0.0 infrastructure and GitOps pipeline

- Migrate from wrapper role to artis3n.tailscale collection

- Make molecule test pass on ansible-core 2.19

- Set ANSIBLE_CONFIG in deploy workflow

- Complete nginx-proxy-manager healthcheck parameters

- Change image fallback from latest to v1.19.5

- Remove dead vault_ansible_become_password from sample

- SHA-pin actions in changelog workflow

- Track encrypted vault, untrack vendored tailscale role

- Write .env for all secrets-bearing services

- Add missing variables for compose-sync test

- Comply with ansible-lint naming conventions

- Implement global log rotation, fixed UID/GID, and universal .env injection

- Reliability hardening - add resource limits, healthchecks, and admin port to core services

- Reliability hardening - add resource limits, healthchecks and environment variables to web services

- Reliability hardening - add resource limits and healthchecks to monitoring/infrastructure services

- Fix fail2ban undefined var, role resolution, and tailscale recursion

- Add GitOps deploy workflow via Tailscale + Ansible

- Add tailscale role, requirements.yml, wire into playbook and CI

- Pin all requirements.txt dependencies to exact versions

- Add permissions block, SHA-pin third-party actions

- Change dist-upgrade to safe upgrade to prevent unattended kernel installs

- Pin remaining unpinned Docker images to specific versions

- Service_healthy in depends_on

- True with specific capabilities on cadvisor and glances

- Bind proxy-backed service ports to 127.0.0.1

- Scope mount from / to /opt/minerva-deploy, bind port to 127.0.0.1

- Notify handler on compose file changes, wire restart_services var

- Replace host_key_checking=False with StrictHostKeyChecking=accept-new

- Replace deprecated SSH directive, remove ssh port var, drop dead become_password

- Remove leaked npm widget credentials from services.yaml

- Update GitHub repository references in changelog configuration

- Add fail2ban with configurable SSH jail

- Add UFW firewall with configurable port allowlist

- Add default vars for UFW and fail2ban

- Git actions

- Correct n8n env vars for nginx-proxy-manager setup

- Add komodo and n8n env vars to compose_sync_secrets

- Implement role with molecule tests passing

- Add compose-up role to pipeline

- Add role with molecule tests - SSH hardening, updates, hushlogin

- Add role with molecule tests

- Add role with molecule tests - creates ansible and minerva users

- Healthcheck dozzle, config files for homepage

- Add N8N_HOST and NODE_ENV environment variables in n8n Docker Compose configuration

- Add N8N_PROTOCOL environment variable in n8n Docker Compose configuration

- Update healthcheck URL in ntfy Docker Compose configuration

- Update glances Docker Compose configuration and remove it-tools service

- Remove tmpfs configuration and adjust privileges in glances Docker Compose

- Remove version specification from Docker Compose for it-tools service

- Correct service names and paths in Docker Compose files

- Add Docker Compose configuration for it-tools service

- Update HOMEPAGE_ALLOWED_HOSTS to include home.nlab.casa

- Update HOMEPAGE_ALLOWED_HOSTS to include additional allowed hosts

- Add base URL configuration to homepage settings

- Update volume paths in Docker Compose for homepage service to use absolute paths

- Add healthcheck configuration for nginx-proxy-manager service in Docker Compose

- Update Grafana service volume path in Docker Compose to use named volume

- Update volume path in Docker Compose for Grafana service to use named volume; change script permissions for execution

- Add Docker Up playbook and corresponding script with logging

- Update volume path in Docker Compose for Grafana service to use relative path

- Remove trailing newline at the end of main.yml

- Streamline deployment tasks by removing git cloning and ensuring directory structure

- Update volume paths in Docker Compose for homepage service

- Update deployment tasks to use dynamic git destination variable

- Add mealie and n8n services with Docker Compose configurations

- Change homepage service restart policy to 'unless-stopped'

- Update Docker Compose configurations for Grafana and Homepage services

- Remove unnecessary MCP server setting from VSCode configuration

- Correct YAML syntax in harden-ssh.yml

- Refactor system initialization tasks and add Docker compose configurations

- Enhance setup script with virtual environment creation and alias setup; add playbook runner script

- Update setup script and Ansible inventory structure; enhance SSH hardening tasks

- Execution of Minerva Deploy v1.0.0 implementation

- Update GitHub repository references in changelog configuration

- Add fail2ban with configurable SSH jail

- Add UFW firewall with configurable port allowlist

- Add default vars for UFW and fail2ban

- Git actions

- Correct n8n env vars for nginx-proxy-manager setup

- Add komodo and n8n env vars to compose_sync_secrets

- Implement role with molecule tests passing

- Add compose-up role to pipeline

- Add role with molecule tests - SSH hardening, updates, hushlogin

- Add role with molecule tests

- Add role with molecule tests - creates ansible and minerva users

- Healthcheck dozzle, config files for homepage

- Add N8N_HOST and NODE_ENV environment variables in n8n Docker Compose configuration

- Add N8N_PROTOCOL environment variable in n8n Docker Compose configuration

- Update healthcheck URL in ntfy Docker Compose configuration

- Update glances Docker Compose configuration and remove it-tools service

- Remove tmpfs configuration and adjust privileges in glances Docker Compose

- Remove version specification from Docker Compose for it-tools service

- Correct service names and paths in Docker Compose files

- Add Docker Compose configuration for it-tools service

- Update HOMEPAGE_ALLOWED_HOSTS to include home.nlab.casa

- Update HOMEPAGE_ALLOWED_HOSTS to include additional allowed hosts

- Add base URL configuration to homepage settings

- Update volume paths in Docker Compose for homepage service to use absolute paths

- Add healthcheck configuration for nginx-proxy-manager service in Docker Compose

- Update Grafana service volume path in Docker Compose to use named volume

- Update volume path in Docker Compose for Grafana service to use named volume; change script permissions for execution

- Add Docker Up playbook and corresponding script with logging

- Update volume path in Docker Compose for Grafana service to use relative path

- Remove trailing newline at the end of main.yml

- Streamline deployment tasks by removing git cloning and ensuring directory structure

- Update volume paths in Docker Compose for homepage service

- Update deployment tasks to use dynamic git destination variable

- Add mealie and n8n services with Docker Compose configurations

- Change homepage service restart policy to 'unless-stopped'

- Update Docker Compose configurations for Grafana and Homepage services

- Remove unnecessary MCP server setting from VSCode configuration

- Correct YAML syntax in harden-ssh.yml

- Refactor system initialization tasks and add Docker compose configurations

- Enhance setup script with virtual environment creation and alias setup; add playbook runner script

- Update setup script and Ansible inventory structure; enhance SSH hardening tasks

- Foundation of repo structure starting with ansible
