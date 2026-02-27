#!/bin/bash
set -e

# Helper function for consistent, readable logging
log_step() {
    echo ""
    echo ""
    echo "===================================================================="
    echo ">>> $1"
    echo "===================================================================="
    echo ""
}

log_step "Starting Minerva Playbook Execution..."

# Ensure the script runs from the project root
# We are in scripts/, so we go up one level
cd "$(dirname "$0")/.."

# Activate the virtual environment if it's not already
log_step "Activating the virtual environment..."
source .venv/bin/activate

# Change to the ansible directory where the playbook and cfg file are located
cd ansible

# Run the playbook, passing along any arguments provided to this script
# e.g., ./run-playbook.sh --ask-become-pass

log_step "Running Ansible Playbook..."
ansible-playbook playbook.yml "$@"

log_step "Playbook execution finished successfully."
