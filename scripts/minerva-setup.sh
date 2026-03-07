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
    python3.11 -m venv .venv
else
    log_step "Virtual environment already exists. Skipping creation."
fi

# 2. Activate the environment for this script's execution
log_step "Activating the virtual environment..."
source .venv/bin/activate

# 3. Install items from requirements.txt
log_step "Installing Python dependencies..."
pip install -r requirements.txt

log_step "Installing Ansible Galaxy Roles..."
ansible-galaxy install geerlingguy.docker -p ansible/roles

log_step "Installing Ansible Galaxy Collections..."
ansible-galaxy collection install community.docker:3.9.0

chmod +x scripts/minerva-wipe.sh

log_step "Minerva Preparations Complete!"