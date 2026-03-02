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

log_step "Starting Docker Up Playbook Execution..."

# Ensure the script runs from the project root
# We are in scripts/, so we go up one level
cd "$(dirname "$0")/.."

# Activate the virtual environment if it's not already
log_step "Activating the virtual environment..."
source .venv/bin/activate

# Change to the ansible directory where the playbook and cfg file are located
cd ansible

# Run the playbook, passing along any arguments provided to this script
log_step "Running Docker Up Playbook..."
ansible-playbook docker-up.yml "$@"

log_step "Docker Up Playbook execution finished successfully."
