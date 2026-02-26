#!/bin/bash
set -e

echo ""
echo ""
echo "Running minerva-playbook.sh..."
echo ""

# Ensure the script runs from the project root
cd "$(dirname "$0")"

# Activate the virtual environment if it's not already
if [ -z "$VIRTUAL_ENV" ]; then
    echo "Activating Python virtual environment..."
    source .venv/bin/activate
fi

# Change to the ansible directory where the playbook and cfg file are located
cd ansible

# Run the playbook, passing along any arguments provided to this script
# e.g., ./run-playbook.sh --ask-become-pass

ansible-playbook playbook.yml "$@"

echo ""
echo "Playbook execution finished."
echo ""
echo ""