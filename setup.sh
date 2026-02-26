#!/bin/bash
set -e  # Exit immediately if any command fails

# Ensure the script runs from the project root, regardless of where it is called
cd "$(dirname "$0")"

# 1. Create the virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv .venv
fi

# 2. Activate the environment for this script's execution
source .venv/bin/activate

# 3. Upgrade pip (removes the warning)
echo "Upgrading pip..."
pip install --upgrade pip

# 4. Install dependencies
echo "Installing Python and Ansible dependencies..."
pip install -r requirements.txt
ansible-galaxy install -r ansible/requirements.yml

echo "Setup complete! Run 'source .venv/bin/activate' to start working."