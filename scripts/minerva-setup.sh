#!/bin/bash
set -e  # Exit immediately if any command fails

# Helper function for consistent, readable logging
log_step() {
    echo ""
    echo ""
    echo "===================================================================="
    echo ">>> $1"
    echo "===================================================================="
    echo ""
}

log_step "Starting Minerva Setup Initialization"

# Ensure the script runs from the project root, regardless of where it is called
# We are in scripts/, so we go up one level
cd "$(dirname "$0")/.."

# 1. Create the virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    log_step "Creating Python virtual environment (.venv)..."
    python3 -m venv .venv
else
    log_step "Virtual environment already exists. Skipping creation."
fi

# 2. Activate the environment for this script's execution
log_step "Activating the virtual environment..."
source .venv/bin/activate

# 3. Upgrade pip (removes the warning)
log_step "Upgrading pip to the latest version..."
pip install --upgrade pip

# 4. Install dependencies
log_step "Installing Ansible Core (>=8.0.0)..."
pip install "ansible>=8.0.0"

log_step "Installing Ansible Lint..."
pip install ansible-lint 

log_step "Installing Python Docker SDK..."
pip install docker

log_step "Installing Python Requests library..."
pip install requests

log_step "Installing Ansible Galaxy Roles..."
ansible-galaxy install geerlingguy.docker -p ansible/roles

log_step "Installing Ansible Galaxy Collections..."
ansible-galaxy collection install community.docker:3.9.0

# Make the playbook runner script executable
chmod +x scripts/minerva-playbook.sh
chmod +x scripts/minerva-wipe.sh
chmod +x scripts/minerva-alias.sh
chmod +x scripts/minerva-help.sh

# 5. Configure Shell Alias
log_step "Configuring shell aliases..."
./scripts/minerva-alias.sh

log_step "Minerva Preparations Complete!"

read -p "Do you want to run the execute playbook.yml now? (y/n): " run_playbook
if [[ "$run_playbook" =~ ^[Yy] ]]; then
    # Run the playbook script with sudo password prompt
    ./scripts/minerva-playbook.sh -K
fi

echo "Run 'minerva-help' for list of custom commands and usage instructions."
echo ""
exec $SHELL # Start a new shell session to apply the alias immediately