# Minerva Deploy

A unified monorepo for deploying and managing the Minerva homeserver infrastructure using Ansible and Docker. This project replaces the legacy `docker-minerva` and `ansible-minerva` repositories with a cleaner, more secure workflow.

## Installation & Setup

This project uses a **Python Virtual Environment** to ensure all developers use the exact same versions of Ansible and Docker tools. This prevents conflicts with your system-wide packages.

### Prerequisites
*   **Git**
*   **Python 3** (and `pip`)
*   **SSH Access** to the target server (ensure your public key is on the server)

### Step 1: Clone the Repository
Download the project to your local machine.

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
bash minerva-setup.sh
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