#!/bin/bash
set -e  # Exit immediately if any command fails

echo ""
echo ""
echo "Running minerva-setup.sh..."
echo ""
echo ""

# Ensure the script runs from the project root, regardless of where it is called
cd "$(dirname "$0")"

# 1. Create the virtual environment if it doesn't exist
echo "Creating the virtual environment..."
echo ""
if [ ! -d ".venv" ]; then
    echo "Creating Python virtual environment..."
    echo ""
    python3 -m venv .venv
fi

# 2. Activate the environment for this script's execution
echo "Activating the virtual environment..."
echo ""
source .venv/bin/activate

# 3. Upgrade pip (removes the warning)
echo "Upgrading pip..."
echo ""
pip install --upgrade pip

# 4. Install dependencies
echo "Installing Python and Ansible dependencies..."
echo ""
pip install -r requirements.txt
ansible-galaxy install -r ansible/requirements.yml -p ansible/roles
ansible-galaxy collection install -r ansible/requirements.yml

# Make the playbook runner script executable
chmod +x minerva-playbook.sh

# 5. Configure Shell Alias
echo "Setting up 'minerva-playbook' alias for easy playbook execution..."
echo ""
ALIAS_ADDED=false
RC_FILE=""
case "$SHELL" in
  */zsh) RC_FILE="$HOME/.zshrc" ;;
  */bash) RC_FILE="$HOME/.bashrc" ;;
esac

if [ -n "$RC_FILE" ] && [ -f "$RC_FILE" ]; then
    PROJECT_DIR=$(pwd)
    ALIAS_CMD="alias minerva-playbook='$PROJECT_DIR/minerva-playbook.sh'"
    if ! grep -q "alias minerva-playbook" "$RC_FILE"; then
        echo "Adding 'minerva-playbook' alias to $RC_FILE..."
        echo "" >> "$RC_FILE"
        echo "# Minerva Deploy Alias" >> "$RC_FILE"
        echo "$ALIAS_CMD" >> "$RC_FILE"
        ALIAS_ADDED=true
    fi
fi

echo "Finalizing setup..."
read -p "Press Enter to continue to sudo password prompt for playbook execution..."

# Run the playbook script with sudo password prompt
./minerva-playbook.sh -K

echo "Setup complete!"
echo "Use 'minerva-playbook' to run the playbook."
echo ""
exec $SHELL # Start a new shell session to apply the alias immediately