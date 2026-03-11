# Refactoring Checklist: minerva-deploy v1.0.0

A scrutiny-driven checklist to guide refactoring toward v1.0.0. Each item challenges an assumption, identifies a gap, or prompts a decision. Work through these before and during implementation — resolve the questions first, then build.

---

## 0. Security Audit Findings

Priority fixes from external security review. Resolve these before or during the first deploy — they represent real exposure, not theoretical risk.

### Critical

- [ ] **Leaked credentials in git history:** `compose/homepage/config/services.yaml:102-103` contains a commented-out email (`bnexcess@gmail.com`) and password (`bnexcess`) for the NPM widget. Even commented, it's permanently in git history. Scrub with BFG Repo-Cleaner, rotate the credential, and verify it hasn't been reused elsewhere. All forks and local clones must be re-cloned after the history rewrite.
- [ ] **Filebrowser mounts entire host root:** `compose/filebrowser/compose.yml:11` maps `/:/srv` — full host filesystem read-write access from a web UI. `user: 1000:1000` and `no-new-privileges:true` are insufficient mitigations — a web exploit gets everything. What directory should filebrowser actually serve? (`/home/operator`? `/opt/minerva-deploy`? A dedicated `/srv/files`?)
- [ ] **privileged: true on cadvisor and glances:** Neither container needs full kernel privileges. cadvisor needs `--device /dev/kmsg` and its existing read-only mounts. Glances needs capabilities `SYS_PTRACE` + `DAC_READ_SEARCH` at most. Replace `privileged: true` with specific `devices:` and `cap_add:` entries.

### High

- [ ] **All service ports bind 0.0.0.0:** Services behind the reverse proxy (Grafana `:4000`, Prometheus `:9090`, Dozzle `:9999`, Uptime Kuma `:3001`, cAdvisor `:8082`, n8n `:5678`, Mealie `:9925`, File Browser `:8383`, ntfy `:2222`, Homepage `:3002`, Komodo `:9120`) are directly accessible on the LAN, bypassing NPM auth and SSL. Bind these to `127.0.0.1:port:port`. Which services genuinely need LAN-wide access? (AdGuard DNS `:53`, NPM `:80`/`:443` — yes. NPM admin `:81` — debatable.)
- [ ] **host_key_checking = False in ansible.cfg:7:** Disables all SSH host key verification. An attacker on the LAN could MITM the Ansible connection. Replace with `StrictHostKeyChecking=accept-new` under `[ssh_connection]` — trusts on first connect, rejects if the key changes.
- [ ] **CI workflow has no permissions block:** `ci.yml` runs with default `contents: read-write` token. Combined with tag-pinned (not SHA-pinned) third-party actions (`@v4`, `@v5`, `@v6`), a supply-chain attack on any action could write to the repo. Fix: add `permissions: { contents: read }` at the workflow level and SHA-pin at least `actions/checkout` and `actions/setup-python`.
- [ ] **SSH port change locks out the playbook mid-run:** The harden role writes `Port {{ harden_ssh_port }}` to sshd_config and the handler restarts sshd, but `ansible_port` is never set in `all.yml` (defaults to 22). If `minerva_ssh_port` is changed from 22, sshd restarts on the new port and all subsequent roles fail to connect. Fix: add `ansible_port: "{{ minerva_ssh_port }}"` to the connection vars in `all.yml`.
  - *Decision:* Standardize on port 22. Remove all `minerva_ssh_port` and `harden_ssh_port` vars and configuration from the harden role, `all.yml`, and tests.
- [ ] **Tailscale for secure deployment:**
  - Create a new `tailscale` role wrapping `artis3n/ansible-role-tailscale` via `requirements.yml`.
  - Add role to playbook order: `bootstrap` -> `harden` -> `tailscale` -> `geerlingguy.docker` -> ...
  - Set `vault_tailscale_auth_key` in vault (reusable, pre-authenticated).
  - Add UDP `41641` to `harden_ufw_allowed_udp_ports`.
- [ ] **13 of 15 services have unpinned images:** `mongo`, `adguardhome`, `ntfy`, and `n8n` have no tag at all (implicit `:latest`). Nine others use `:latest` explicitly. Only cadvisor (`v0.49.1`) and Komodo (`v1.19.5` via `.env`) are pinned. A `docker compose pull` could introduce breaking changes across the entire stack.
- [ ] **Compose file changes don't trigger service restarts:** `compose-sync/tasks/main.yml:20` — the file copy task has no `notify` handler. Only `.env` changes (line 42) trigger the restart handler. If you update an image tag or port mapping in `compose.yml`, the running container is unchanged until a manual restart.
- [ ] **CI dependencies are unpinned:** `requirements.txt` has `ansible>=8.0.0` with no upper bound; other packages have no pins at all. GitHub Actions use mutable tag refs (`@v4`). Builds are not reproducible — the same workflow could produce different results on different days.

### Medium

- [ ] **NOPASSWD: ALL vs. ansible_become_password:** Bootstrap grants passwordless sudo for the `ansible` user, but `all.yml:139` sets `ansible_become_password` from vault. The password is dead code — Ansible sends it, sudo ignores it. This creates a false sense of security (someone might think the password protects sudo). Drop the vault var and the `ansible_become_password` line.
- [ ] **dist-upgrade runs unconditionally:** `harden/tasks/install-updates.yml` runs `apt dist-upgrade` on every deploy. This can install new kernels, remove packages, or require reboots — dangerous for unattended automated deploys. Use `upgrade: safe` (equivalent to `apt upgrade`) for the standard pipeline. Reserve `dist-upgrade` for a manual maintenance playbook.
- [ ] **Incomplete SSH hardening:** Missing `MaxAuthTries`, `ClientAliveInterval`/`ClientAliveCountMax`, `X11Forwarding no`, and `AllowUsers`/`AllowGroups`. Uses the deprecated `ChallengeResponseAuthentication` directive (renamed to `KbdInteractiveAuthentication` in OpenSSH 8.7+) — Ubuntu 24.04's sshd may silently ignore the old name.
- [ ] **Komodo depends_on without health condition:** `compose/komodo/compose.yml` uses bare `depends_on: mongo` without `condition: service_healthy`. Komodo Core can start and fail before MongoDB is accepting connections. Add a healthcheck to the `mongo` service and use `condition: service_healthy`.
- [ ] **Docker socket mounted in 5 containers without proxy:** Dozzle, Glances, Homepage, Komodo Periphery, and Filebrowser (via the `/` mount) all have root-equivalent host access through `docker.sock`. A Docker socket proxy (e.g., `tecnativa/docker-socket-proxy`) would restrict API calls per container. Evaluate whether the added complexity is justified for a LAN-only homelab, or whether fixing the filebrowser `/` mount is sufficient for v1.0.0.

### Low

- [ ] **No `read_only: true` or `no-new-privileges` on most containers:** Only filebrowser sets `no-new-privileges:true`. Adding `read_only: true` (with explicit tmpfs for write-needed paths) and `security_opt: [no-new-privileges:true]` to all containers reduces attack surface.
- [ ] **Docker networks created without subnet config:** Docker defaults could theoretically conflict with the LAN's `192.168.x.x` range. Specifying subnets (e.g., `172.18.0.0/16` for monitoring, `172.19.0.0/16` for networking) prevents surprises.
- [ ] **Glances mounts a Podman socket** (`/run/user/1000/podman/podman.sock`) that doesn't exist on an Ubuntu Docker host. Harmless but produces a noisy warning. Remove or make conditional.

**Decisions needed:** Filebrowser mount scope. Docker socket proxy (yes/no for v1.0.0). Which ports need LAN-wide access vs. 127.0.0.1. SSH port lockout fix approach.

---

## 1. Development Environment

- [ ] `minerva-setup.sh` creates a venv unconditionally — should it check for an existing `.venv/` first? Re-running the script could reinstall everything or conflict with manually-installed packages.
- [ ] The script hardcodes `python3.11` — what if the developer has 3.12 or 3.13? Should it accept any 3.11+, use `python3` and verify the version, or pin via `.python-version`?
- [ ] `pip install -r requirements.txt` runs without `--upgrade` — intentional (stability) or oversight (stale packages on re-run)?
- [ ] `.envrc` activates the venv via direnv, but the README doesn't list direnv as a prerequisite. Should it, or should `source .venv/bin/activate` be the primary documented path?
- [ ] `ansible-galaxy install geerlingguy.docker -p ansible/roles` in the setup script isn't idempotent — if the role directory exists, galaxy may error or silently skip. Should it use `--force`, check first, or use a `requirements.yml`?
- [ ] No `Makefile`, `justfile`, or `taskfile` exists for common operations (`lint`, `test`, `deploy`, `setup`). Would a task runner reduce friction, or is it overhead for a single operator?
- [ ] No pre-commit hooks for linting — should `ansible-lint` or `commitlint` run locally before commit, or is CI-only enforcement sufficient?
- [ ] `.vault_pass` lives at the repo root — is this the right location? Could it be in `~/.ansible/` to further reduce accidental exposure risk, or does `ansible.cfg`'s relative path make that awkward?
- [ ] `.envrc` doesn't guard against a missing `.venv/` — if direnv is active but setup hasn't run, entering the directory errors on every shell prompt. Should `.envrc` check for `.venv/bin/activate` before sourcing it?

**Decisions needed:** Idempotency strategy for setup (fix, rewrite, or replace?). Task runner adoption (make/just/task?). Pre-commit hooks (yes/no?).

---

## 2. Repository Folder Structure

- [ ] `compose/` and `ansible/` are siblings at the root — compose-sync rsyncs from `compose/` to the server. If Jinja2 templates are added for service configs, should rendered templates live in `ansible/templates/`, alongside their compose files in `compose/{service}/`, or in a `build/` directory (gitignored)?
- [ ] `docs/` exists but is empty (until now) — what should its structure be? Specs, runbooks, ADRs, architecture diagrams?
- [ ] `scripts/` contains two utilities, one broken — is this the right home for operator tooling, or should it be absorbed into a Makefile or Ansible role?
- [ ] `media/` holds logo PNGs for the README — does branding belong in the deployment repo, or is this fine for a personal project?
- [ ] No `ansible/templates/` directory at the playbook level — templates live only in `harden/templates/`. As IaC expands, where should cross-role or shared templates live?
- [ ] Some `compose/*/` directories have `.gitkeep` files and some don't — is the pattern consistent? Should every service directory follow the same structure?
- [ ] No `ansible/playbooks/` directory — if `wipe.yml`, `deploy-single-service.yml`, or `smoke-test.yml` are added, should there be a playbooks subdirectory, or should they stay at `ansible/` root?

**Decisions needed:** Template file location strategy. `docs/` structure. Whether to support multiple playbooks and where they live.

---

## 3. GitHub Actions (CI Workflows, Linting, Molecule, Changelog, Dependabot)

- [ ] CI triggers on both `push: main` and `pull_request: main` — a merged PR fires CI twice (once on the PR event, once on the push to main). Is the double run intentional, or should push-to-main only trigger the deploy workflow?
- [ ] No deploy workflow exists yet — `deploy.yml` must SSH into Minerva and run `ansible-playbook`. What secrets does it need? (`SSH_PRIVATE_KEY`, `VAULT_PASSWORD`, `MINERVA_IP`, `SSH_PORT` at minimum.) How does it handle SSH host key verification?
  - *Decision:* Workflow runs on push to `main`. Runner uses `tailscale/github-action@v2` to temporarily join tailnet. Execs playbook against Minerva's Tailscale IP over standard port 22.
- [ ] `changelog.yml` generates a changelog and opens a PR — but commit `fc71081` recently removed `docs/meta/changelog.md`. Is the changelog workflow still active and desired, or should it be removed/reworked?
- [ ] `.github/dependabot.yml` is referenced in `CLAUDE.local.md` but does not exist in the repo. Should it be created for `pip` (requirements.txt) and `github-actions` (workflow action versions)?
- [ ] The Molecule matrix tests 4 roles independently — no job runs the full 5-role pipeline in sequence. Can Molecule simulate the full pipeline, or is integration testing only possible on real hardware?
- [ ] CI installs `community.docker:3.9.0` with an exact version pin. Is 3.9.0 still current? Should it float within a major version (e.g., `>=3.0,<4.0`), or is exact pinning the right trade-off for reproducibility?
- [ ] CI writes `.vault_pass` from `secrets.VAULT_PASSWORD` — the lint job needs it to resolve vault references. Is this secret scoped correctly (repo-level vs. org-level)? Could a read-only dummy vault work for lint instead?
- [ ] No CI caching for pip or galaxy dependencies — every run installs from scratch. Is `actions/cache` for `.venv/` and galaxy roles worth the config complexity?
- [ ] `cliff.toml` skips `docs`, `style`, `test`, `chore`, and `ci` commit types from the changelog. Is this the right filter? Should `refactor` commits appear in the changelog?
- [ ] The changelog PR uses `peter-evans/create-pull-request` — does this work reliably with branch protection rulesets? Does it require a PAT or bot account?
- [ ] **[Security]** `ci.yml` has no `permissions:` block — all jobs run with default `contents: read-write`. Add `permissions: { contents: read }` at the workflow level. Only the changelog workflow needs write access.
- [ ] **[Security]** Third-party actions are pinned by mutable tag (`actions/checkout@v4`), not by SHA. A compromised tag update could execute arbitrary code with the workflow's token. SHA-pin at least the high-risk actions (`checkout`, `setup-python`). Dependabot can auto-update SHA pins.
- [ ] **[Security]** `requirements.txt` pins nothing except an `ansible` floor (`>=8.0.0`). `molecule`, `ansible-lint`, `docker`, `requests` all float. Add version pins (or use `pip-compile` / `pip freeze` to generate a lockfile) for reproducible CI builds.

**Decisions needed:** CI trigger strategy (avoid double runs). Deploy workflow design. Changelog workflow status. Dependabot creation. CI caching. Action SHA-pinning strategy.

---

## 4. Ansible IaC (Playbook Structure, Role Design, Task Organization)

- [ ] `playbook.yml` runs all 5 roles unconditionally with no tags. Can you deploy just compose-sync + compose-up without re-running bootstrap and harden? Should each role (or logical group) be tagged for selective execution?
- [ ] `become: true` is set at the play level — but compose-up runs `docker compose up`, which arguably should run as the `minerva` user (owns the files). Is running everything as root the right privilege model, or should compose tasks use `become_user: minerva`?
- [ ] No role dependencies declared in any `meta/main.yml` — compose-up implicitly depends on compose-sync (files must exist). Should this be declared, or is sequential ordering in `playbook.yml` sufficient?
- [ ] `ansible.cfg` sets `roles_path = roles` (relative path) — Ansible must be invoked from the `ansible/` directory. Is this fragile? Should the config use an absolute path or `{{ playbook_dir }}/roles`?
- [ ] `ansible.cfg` enables `pipelining = true` for performance — this requires `requiretty` to be absent from sudoers. Does the bootstrap role's sudoers template account for this?
- [ ] The inventory has a bare `minerva` host under `[minerva]` with the actual IP set in `all.yml` via `ansible_host`. Is this indirection clear to a returning developer, or should the IP be in the inventory file itself?
- [ ] No handler exists for "restart all services" — compose-sync has per-service restart handlers, but what about a full-stack restart or a "bounce everything" operation?
- [ ] compose-sync uses the `synchronize` module (rsync) — is rsync guaranteed on a fresh Ubuntu 24.04 install? If not, should the harden role install it, or should compose-sync use `ansible.builtin.copy` instead?
- [ ] No `--check` (dry-run) support — should there be a documented way to preview what a deploy would change before applying? Does the playbook work correctly in check mode?
- [ ] No `--limit` or host targeting capability — the inventory has one host, but should the playbook support `--limit` for future multi-host scenarios, or is that out of scope?
- [ ] **[Security]** `ansible.cfg:7` sets `host_key_checking = False` — disables SSH host key verification globally. Replace with `StrictHostKeyChecking=accept-new` under `[ssh_connection]` (trust on first connect, reject changes).
- [ ] **[Bug]** `ansible_port` is never set in `all.yml` — if `minerva_ssh_port` changes from 22, the harden role restarts sshd on the new port but Ansible keeps trying port 22. Add `ansible_port: "{{ minerva_ssh_port }}"` to the connection vars block.
  - *Decision:* Standardize on port 22 instead to simplify configuration, relying on Tailscale for security boundary.
- [ ] **[Bug]** compose-sync's file copy task (`tasks/main.yml:20`) has no `notify` handler — only `.env` writes (line 42) trigger service restarts. Changes to `compose.yml` files (image tags, ports, volumes) are deployed but the running containers are never updated.

**Decisions needed:** Tag strategy for selective role execution. Privilege model (root vs. minerva). rsync dependency. Dry-run support. SSH port lockout fix.

---

## 5. Jinja2 Templates (Current Templates, What Else Should Be Templated)

- [ ] Only one template exists: `harden/templates/jail.local.j2`. The IaC goal demands many more. Prioritize: which service configs are highest-value to template first?
- [ ] `compose/prometheus/prometheus.yml` hardcodes scrape targets (`localhost:9090`, `node_exporter:9100`, `cadvisor:8080`). Should these be templated from `all.yml` so adding a scrape target is a variable change?
- [ ] `compose/homepage/config/services.yaml` lists 16 services with hardcoded ports and URLs. Should this be a Jinja2 template that generates entries from `all.yml`, or is it simpler to edit the YAML directly since it changes rarely?
- [ ] Grafana needs provisioning configs (`datasources.yml`, `dashboards.yml`) to auto-load data sources and dashboards at startup. These files don't exist yet — they must be created as templates and placed in a provisioning volume.
- [ ] `compose/adguardhome/` has no initial config — AdGuard Home generates `AdGuardHome.yaml` on first run and presents a setup wizard. Can a pre-seeded config template bypass the wizard entirely?
- [ ] `compose/glances/glances.conf` is 989 lines of static config. Does any of it need to vary by host (thresholds, plugin enables), or is it stable enough to remain static?
- [ ] Should `compose.yml` files themselves become Jinja2 templates? Image tags could be `{{ grafana_image_tag }}` instead of hardcoded. This enables centralized version control via `all.yml`, but adds complexity to the sync pipeline.
- [ ] If compose files are templated, compose-sync must render them before syncing. This changes the role from a simple rsync to a template-render-then-sync pipeline. Is that acceptable complexity?
- [ ] Where should rendered output go — a local `build/` directory (gitignored, then rsynced) or rendered directly on the target host via `ansible.builtin.template`?
- [ ] How will templates be validated? Invalid YAML/JSON in a rendered template could break a service. Should Molecule tests render templates and validate the output?

**Decisions needed:** Template priority order. Compose-file templating (yes/no). Rendering strategy (local vs. remote). Template validation.

---

## 6. Molecule Testing (Coverage, Accuracy, Gaps, Docker-in-Docker Quirks)

- [ ] All tests use `geerlingguy/docker-ubuntu2404-ansible` with full systemd — matches the target OS, but Docker-in-Docker means some behaviors are simulated. What are the tests actually proving vs. what requires real hardware?
- [ ] UFW verify checks `/etc/ufw/user.rules` file content but can't test packet filtering inside a Docker container. Is this test providing useful signal or false confidence?
- [ ] fail2ban verify checks that `jail.local` exists with correct values but can't test actual IP banning. Same question — useful signal or false confidence?
- [ ] compose-up test mounts `docker.sock` and runs real containers inside the Molecule container. This works locally but is fragile — does it reliably pass in GitHub Actions runners?
- [ ] compose-sync test creates dummy data in `/tmp/compose-test/` — the test path doesn't match production (`/opt/minerva-deploy`). Could path-dependent bugs slip through?
- [ ] No test runs the full 5-role pipeline end-to-end. If role execution order matters (and it does — compose-sync must run before compose-up), how is the integration validated?
- [ ] No negative tests exist — what happens if bootstrap runs on a server where the users already exist? If a port is already bound when compose-up runs? Are idempotency and error paths tested?
- [ ] Molecule verify scripts use raw `shell` commands and `stat` for assertions. Could `ansible.builtin.user`, `ansible.builtin.service_facts`, or `ansible.builtin.assert` produce more reliable and readable tests?
- [ ] As IaC templates are added (Grafana provisioning, Homepage config, etc.), how will they be tested? Can Molecule verify that a rendered template is valid YAML/JSON and contains expected values?
- [ ] Molecule `converge.yml` files apply roles with minimal variables — do they match the variable structure used in production (all.yml → role defaults → overrides)? Could a test pass with test vars but fail with production vars?
- [ ] Harden role's Molecule verify hardcodes `Port 22` instead of referencing the variable `harden_ssh_port`. If the default changes, the test silently checks the wrong value.
- [ ] No Molecule test verifies that handlers actually fire — e.g., does the SSH restart handler run after config changes? Does the compose-sync restart handler trigger when `.env` changes? Handler logic is a common source of "works in test, breaks in prod" bugs.

**Decisions needed:** Which testing gaps are acceptable (UFW, fail2ban behavior vs. config correctness). Integration test feasibility. Template validation in tests. Test variable fidelity.

---

## 7. Linting (ansible-lint, commitlint, Config, Exclusions)

- [ ] `.ansible-lint` only excludes `geerlingguy.docker/`. As the codebase grows, will other exclusions be needed? Do Molecule test playbooks get linted (they shouldn't follow the same rules as production)?
- [ ] No explicit `.yamllint` config exists — ansible-lint uses built-in yamllint rules. Should there be a standalone config for finer control (line length, truthy values, comment spacing)?
- [ ] `.commitlintrc.yml` enforces conventional commits with lowercase scopes — but no scopes are defined. Should there be an allowed list (e.g., `bootstrap`, `harden`, `compose`, `ci`, `docs`, `deps`)?
- [ ] No `hadolint` or `docker compose config` validation in CI — compose files are checked for YAML syntax only, not Docker Compose schema validity. Worth adding?
- [ ] No `shellcheck` for `scripts/` — both scripts have potential issues (unquoted variables, missing `set -e`). Should shellcheck be a CI step?
- [ ] `ansible-lint` runs on `ansible/playbook.yml` — does it follow `include_role` and `include_tasks` directives to lint all role files, or does it only check the playbook itself?
- [ ] As Jinja2 templates are added, should `j2lint` or a custom validation step be added to CI? Broken templates are silent until deploy time.

**Decisions needed:** yamllint config (standalone or rely on ansible-lint defaults). Commit scopes (define allowed list or keep open). Add hadolint/shellcheck/j2lint to CI?

---

## 8. Variable Mapping and Logic (all.yml, Role Vars, Vault Vars, Naming Conventions)

- [ ] `all.yml` defines "canonical" vars and "derived" role vars — but the derived vars are aliases (e.g., `compose_sync_owner: "{{ minerva_user }}"`). Why not reference `minerva_user` directly in the roles? What does the indirection provide — role portability across projects, or just noise?
- [ ] Role `defaults/main.yml` set values that `all.yml` overrides (e.g., harden defaults `harden_ssh_port: 22`, all.yml sets `harden_ssh_port: "{{ minerva_ssh_port }}"`). This is standard Ansible layering, but is it clear to a returning developer that the defaults are effectively dead code?
- [ ] `compose_sync_secrets` is a dict-of-dicts in `all.yml` with mixed vault references and literal values. Is this the best structure, or should secrets be a flat list of `{service, key, value}` tuples?
- [ ] Vault variable naming is inconsistent — `vault_cf_api_token` (no service prefix) vs. `vault_komodo_db_password` (service-prefixed). Should all vault vars follow a `vault_{service}_{key}` convention?
- [ ] With IaC maximization, `all.yml` will grow significantly — service ports, hostnames, feature flags, template values. How should it be organized? Sections with comments? Separate files per service (e.g., `group_vars/all/grafana.yml`)?
- [ ] No variable validation exists — if someone deploys with `minerva_ip: 192.168.1.100` (the sample default), Ansible proceeds targeting the wrong host. Should there be `assert` tasks that fail if required variables aren't changed from defaults?
- [ ] `compose_up_services` and `compose_up_manual_services` are manually-maintained lists that must match `compose/` directory contents. Can these be derived automatically (e.g., by reading the compose directory), or does explicit listing provide valuable control?
- [ ] Service ports are hardcoded in compose files, Homepage's `services.yaml`, and potentially NPM proxy host configs. If ports are promoted to `all.yml` variables, how many files need updating? This is a strong signal that ports should be centralized.
- [ ] **[Security]** `ansible_become_password` is set from vault in `all.yml:139`, but bootstrap grants `NOPASSWD: ALL` — the password is dead code. Ansible sends it, sudo ignores it. This creates confusion about the security model. Remove the vault var and the `ansible_become_password` line.
- [ ] Connection vars (`ansible_host`, `ansible_user`, `ansible_become_password`, `ansible_ssh_private_key_file`) are set in `all.yml` alongside application vars. Should they move to `host_vars/minerva.yml` to separate connection config from application config?
- [ ] When adding a new service under IaC, what variables does a developer need to add? Is this pattern documented? Can it be validated (e.g., "service X is in `compose_up_services` but has no entry in `compose_sync_secrets`")?

**Decisions needed:** Keep or remove role-var aliasing. Variable file organization for IaC growth. Vault naming convention. Variable validation assertions. Connection vars location.

---

## 9. Purpose of Roles and Their Tasks (Scope, Single Responsibility)

- [ ] **bootstrap** creates two users but doesn't distribute SSH keys — it assumes the `ansible` user's SSH key is already on the server. Should it install `authorized_keys`, or is that handled by the operator during initial OS setup?
- [ ] **harden** installs 19 packages including `vim`, `htop`, `neofetch`, `speedtest-cli`, `iotop` — these are convenience tools, not hardening. Should there be a separate `baseline-packages` role or task file, or is bundling fine for a homelab?
- [ ] **harden** does 5 distinct things: system updates, SSH hardening, UFW, fail2ban, hush-login. Is this too much for one role? The counterargument: splitting adds pipeline complexity for a single-operator project. What's the right call?
- [ ] **harden** installs `python3-docker` — this is a Docker SDK dependency, not a hardening concern. Should it move to a pre-docker step or into `geerlingguy.docker`'s configuration?
- [ ] **harden** runs `apt dist-upgrade` unconditionally — this can install new kernels, remove packages, or require reboots during an automated deploy. Should it use `upgrade: safe` (equivalent to `apt upgrade`) for the standard pipeline, with `dist-upgrade` reserved for manual maintenance?
- [ ] **harden** uses the deprecated `ChallengeResponseAuthentication` directive — OpenSSH 8.7+ renamed it to `KbdInteractiveAuthentication`. On Ubuntu 24.04, the old name may be silently ignored, meaning this hardening rule has no effect. Should all SSH directives be audited against the installed OpenSSH version?
- [ ] **harden** is missing several SSH hardening directives: `MaxAuthTries`, `ClientAliveInterval`/`ClientAliveCountMax`, `X11Forwarding no`, `AllowUsers`/`AllowGroups`. How many of these are relevant for a homelab with key-only auth?
- [ ] **compose-sync** handles both file synchronization AND secret injection (`.env` writing). These are two distinct concerns with different change frequencies. If secrets change but files don't (or vice versa), does the handler logic handle partial updates correctly?
- [ ] **compose-sync** uses the `synchronize` module (rsync push). If templates are rendered on the control node into a build directory, rsync works. If templates should be rendered on the target, the role needs `ansible.builtin.template` instead. Which approach aligns with the IaC plan?
- [ ] **compose-up** creates Docker networks AND starts services. If you need to add a network without restarting services, can you? Should network creation be a separate tagged task?
- [ ] No role exists for **post-deploy service configuration** — Grafana provisioning, Uptime Kuma monitor creation via API, NPM proxy host setup. Should this be a new `configure` or `provision` role in the pipeline, or tasks appended to compose-up?
- [ ] No role exists for **health checks or smoke tests**. Should a `validate` role run after compose-up to verify all services are responding, or is that handled by the deploy workflow?
- [ ] Should `minerva-setup.sh` be absorbed into a `local-setup` Ansible role (as the roadmap suggests), or is that overengineering for a script that only runs on the operator's Mac?

**Decisions needed:** Harden role scope (split or keep unified). New role for post-deploy service provisioning. Validation/smoke-test role. Setup script absorption.

---

## 10. Docker Compose IaC (Image Pinning, Network Design, Service Config, Secrets)

- [ ] **[Security]** `compose/filebrowser/compose.yml:11` maps `/:/srv` — the entire host root filesystem, read-write, via a web UI. Even with `user: 1000:1000`, uid 1000 typically owns the operator's home directory. Scope this to a specific path. What should filebrowser serve?
- [ ] **[Security]** All service ports bind `0.0.0.0` — services behind NPM (Grafana, Prometheus, Dozzle, Komodo, n8n, Mealie, etc.) are directly accessible on the LAN, bypassing auth and SSL. Bind proxy-backed services to `127.0.0.1:port:port`. Audit which services genuinely need LAN-wide access (NPM `:80`/`:443`, AdGuard `:53` — yes; NPM admin `:81` — probably not).
- [ ] 13 services have unpinned images — 4 have no tag at all (`mongo`, `adguardhome`, `ntfy`, `n8n` — implicit `:latest`), 9 use explicit `:latest`. Strategy: query registries for current tags, pin to semver (e.g., `grafana/grafana:11.5.2`), use Dependabot or Renovate for update PRs?
- [ ] `node-exporter` runs with `network_mode: host` so it can't join the `monitoring` network. Prometheus scrapes it via `extra_hosts: node_exporter:host-gateway`. Is this the simplest correct approach, or is there a cleaner way?
- [ ] `glances` runs with `network_mode: host`, `privileged: true`, and `pid: host` — maximum host access. On a hardened server, does this undermine the security model? Is there a less-privileged way to run it?
- [ ] `cadvisor` runs privileged and mounts `/`, `/sys`, `/var/lib/docker`, `/dev` as read-only. Same concern — are there less-privileged alternatives that still provide the needed metrics?
- [ ] No `restart` policy on most services — Docker's default is `no`, meaning services don't survive a host reboot. All services should have `restart: unless-stopped` or `restart: always`. Which policy, and should it be consistent across all services?
- [ ] Named volumes (`prometheus-data`, `grafana-storage`, `mongo-data`) vs. bind mounts (`./data`, `./config`) — the strategy is inconsistent across services. Should there be a standard, and what determines which to use?
- [ ] No resource limits on any service except `mealie` (1000M memory). Should all services have `mem_limit` to prevent a single runaway container from consuming all host RAM?
- [ ] `ntfy` maps external port `2222` to internal port `80` — this is non-obvious and potentially confusing (2222 looks like an SSH port). Is this documented anywhere? Is the port choice deliberate?
- [ ] Komodo's compose uses `${COMPOSE_KOMODO_IMAGE_TAG:-latest}` from `.env`, but all other services hardcode their image tag inline. Should all services use the env-var pattern for consistency, or is it unnecessary complexity for services that don't need it?
- [ ] Some services have healthchecks (NPM, Dozzle, Glances, ntfy) and some don't. Should every service define a healthcheck so `docker compose ps` accurately reflects service health?
- [ ] `compose-up` uses `community.docker.docker_compose_v2` — how does this module handle 15 separate compose directories? Does it iterate with a loop, or does it need one task per service? Is the current implementation tested for this?
- [ ] No `.env.example` files alongside compose files — a developer reading a service's compose directory can't see what environment variables it expects without cross-referencing `all.yml` and `vault.SAMPLE.yml`. Should each service have an `.env.example`?
- [ ] `prometheus/prometheus.yml` is committed as a static config but is rsynced to the server alongside compose files. If it becomes a Jinja2 template, the sync pipeline must render it first. Is this accounted for?
- [ ] **[Security]** `cadvisor` runs `privileged: true` but only needs `--device /dev/kmsg` beyond its read-only mounts. Replace `privileged` with a specific `devices:` entry. Same for `glances` — replace `privileged` with `cap_add: [SYS_PTRACE, DAC_READ_SEARCH]`.
- [ ] **[Bug]** `compose/komodo/compose.yml` uses bare `depends_on: mongo` without `condition: service_healthy`. Komodo Core can crash-loop if MongoDB isn't ready. Add a healthcheck to `mongo` and use `condition: service_healthy`.
- [ ] **[Hygiene]** `compose/glances/compose.yml` mounts `/run/user/1000/podman/podman.sock` — this socket doesn't exist on a Docker-only Ubuntu host. Remove or make conditional via an env var.
- [ ] **[Security]** Only filebrowser has `security_opt: [no-new-privileges:true]`. Should all containers get `no-new-privileges` and `read_only: true` (with explicit tmpfs mounts for write-needed paths) as baseline hardening?
- [ ] Docker networks (`monitoring`, `networking`) are created without explicit subnet configuration. Docker typically assigns from `172.17+.0.0/16`, which shouldn't conflict with `192.168.x.x`, but specifying subnets explicitly avoids surprises.

**Decisions needed:** Image pin format (semver vs. digest). Restart policy standard. Volume strategy (named vs. bind). Resource limits. Healthcheck coverage. `.env.example` pattern. Container security baseline (`no-new-privileges`, `read_only`). Filebrowser mount scope.

---

## 11. README.md (Accuracy, Completeness, Usefulness)

- [ ] README claims "single-command deployment" and "fully-configured server" — with unpinned images and no IaC for service configs, this isn't true yet. Update after v1.0.0, or soften the claim now?
- [ ] Getting Started tells users to run `bash scripts/minerva-setup.sh` — if the script is replaced or absorbed, this section breaks. Should setup instructions be resilient to tooling changes?
- [ ] No mention of `direnv` or `.envrc` — a developer with direnv installed gets automatic venv activation; one without gets confused by the `.envrc` file. Document or remove?
- [ ] Roadmap shows UFW and fail2ban as TODO items — both are implemented and merged. The roadmap is stale.
- [ ] No mention of the deploy pipeline — once GitOps is implemented, the README should describe the CI → deploy flow and how to trigger or monitor it.
- [ ] Architecture diagram labels the operator user as `init` — the rest of the project calls this user `bryan`. Is the terminology consistent?
  - *Decision:* Standardize on `operator`. Update README and all configuration references to `operator`.
- [ ] No troubleshooting section — common issues like vault password errors, SSH connection failures, Docker socket permissions, or "service didn't start" debugging would help a returning developer.
- [ ] No "Adding a new service" guide — with the IaC goal, the process for adding a service (compose file → variables → templates → tests) should be documented.
- [ ] The project structure tree shows `... (15 services)` — is this sufficient, or should all services be listed so a reader can see the full scope?
- [ ] No mention of the three-user model's implications — e.g., "if you SSH in to debug, use `operator`; never `sudo su minerva` to poke at compose files."

**Decisions needed:** When to update the README (before or after v1.0.0). Whether to add a contributing/operations guide, troubleshooting section, and "add a service" walkthrough.

---

## 12. Scripts (minerva-setup.sh, minerva-wipe.sh)

- [ ] `minerva-setup.sh` is the only onboarding path, but it's not idempotent, has no error handling (`set -e` is missing), and hardcodes `python3.11`. Rewrite it, replace it with a Makefile target, or keep it as a thin wrapper around documented manual steps?
- [ ] `minerva-wipe.sh` references `ansible/wipe.yml`, which does not exist — the script is non-functional. Should `wipe.yml` be created (what would it do?), or should the wipe concept be dropped for v1.0.0?
- [ ] `minerva-wipe.sh` has double-confirmation prompts — good UX for a destructive operation. But without `wipe.yml`, the prompts guard nothing. If wipe is kept, what should the playbook actually destroy? (Containers, volumes, data dirs, Docker itself, users?)
- [ ] Neither script has `set -e` or `set -o pipefail` — errors are silently swallowed. Is this acceptable for scripts an operator watches interactively, or should they fail fast?
- [ ] Neither script has a `--help` flag or usage documentation — discoverability is poor.
- [ ] `minerva-setup.sh` does `chmod +x scripts/minerva-wipe.sh` — if the file is committed with execute permission, this is redundant. If it's not, the fix belongs in `.gitattributes` or a one-time `git update-index`, not in a sibling script.
- [ ] Should there be a `minerva-deploy.sh` convenience wrapper around `ansible-playbook ansible/playbook.yml`, or is the raw command simple enough that a wrapper adds confusion?
- [ ] If a `Makefile` or `justfile` is adopted (see section 1), most script functionality migrates there. Do the standalone scripts still serve a purpose, or do they become dead code?

**Decisions needed:** Setup script strategy (rewrite, replace with task runner, or keep as thin wrapper). Wipe script future (create `wipe.yml`, or delete the script). Task runner adoption (if yes, scripts become redundant).
