#!/bin/bash

# Exit immediately if a command exits with a non-zero status (optional, but good for safety)
set -e 

# ANSI color codes for warning visibility
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Ensure we are in the project root to find the playbook
cd "$(dirname "$0")/.."

echo -e "${RED}!!! DANGER ZONE !!!${NC}"
echo -e "Target Machine: ${YELLOW}minerva${NC}"
echo "This script will:"
echo "  1. STOP all running Docker containers."
echo "  2. DELETE all stopped containers, networks, and images."
echo "  3. DELETE ALL VOLUMES (Persistent data will be lost)."
echo ""

# --- Confirmation 1 ---
read -p "Confirmation 1/2: Are you sure you want to proceed? (type 'yes'): " input1
if [ "$input1" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

# --- Confirmation 2 ---
echo ""
echo -e "${RED}WARNING: This action is irreversible. Volume data cannot be recovered.${NC}"
read -p "Confirmation 2/2: Are you ABSOLUTELY sure? (type 'yes'): " input2
if [ "$input2" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "🚀 Initiating system wipe on minerva..."

if [ -f ".venv/bin/ansible-playbook" ]; then
    echo "Using .venv ansible-playbook..."
    .venv/bin/ansible-playbook -i ansible/inventory ansible/wipe.yml
else
    echo "Using system ansible-playbook..."
    ansible-playbook -i ansible/inventory ansible/wipe.yml
fi

echo ""
echo -e "${YELLOW}✅ Docker system wipe complete on minerva.${NC}"
echo ""