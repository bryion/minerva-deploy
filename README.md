# Minerva Deploy

A unified Infrastructure-as-Code (IaC) monorepo for deploying and managing the Minerva homeserver infrastructure. This project leverages **Ansible** for configuration management and **Docker Compose** for service orchestration, targeting **Ubuntu 24.04** bare metal servers.

It replaces legacy manual workflows with a secure, idempotent, and test-driven deployment pipeline.

## Architecture & Stack

*   **Orchestration:** Ansible Core (running in a local Python virtual environment).
*   **Target OS:** Ubuntu 24.04 LTS.
*   **Services:** Docker Compose (GitOps-style config sync).
*   **Testing:** Molecule with Docker driver.
*   **Security:**
    *   **Three-User Model:**
        *   `operator`: You (local developer).
        *   `ansible`: Service account with passwordless sudo (provisioned during bootstrap).
        *   `minerva`: Application user owning the Docker stack (no sudo).
    *   **Secrets:** Encrypted via Ansible Vault; injected as `.env` files at runtime.
    *   **Hardening:** SSH lockdown, UFW firewall management.

## Prerequisites

### Target Server
*   A fresh install of **Ubuntu 24.04**.
*   **SSH Access:** You must have an SSH public key installed for the initial root/admin user.
*   **Static IP:** Recommended for stable service addressing.

### Local Control Node
*   **Git**
*   **Python 3.11+**
*   **Docker** (Required for running Molecule tests locally).

## Installation & Setup

We use a strictly pinned Python Virtual Environment to ensure all developers use the exact same versions of Ansible and its dependencies.

### 1. Clone the Repository

```bash
git clone https://github.com/bryion/minerva-deploy.git
cd minerva-deploy
```

### Step 2: Run the Setup Script
We have bundled the environment creation and dependency installation into a single script. This will:
1.  Create a hidden `.venv` directory.
2.  Upgrade `pip` to the latest version.
3.  Install all Python tools (Ansible, Docker SDK, Linting).
4.  Install required Ansible Collections (e.g., `community.docker`).

Run the script from the project root:

```bash
bash scripts/minerva-setup.sh
```

### Step 3: Activate the Environment
**Important:** You must run this command **every time** you open a new terminal window to work on this project. It tells your shell to use the tools inside the `.venv` folder instead of your global system tools.

```bash
source .venv/bin/activate
```

*You will know it is active when you see `(.venv)` appear at the start of your command prompt.*

### Verification
To confirm everything is working and your SSH connection is valid, run:

```bash
ansible minerva -m ping
```

**Expected Output:**
`minerva | SUCCESS => { ... "ping": "pong" }`