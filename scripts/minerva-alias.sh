#!/bin/bash
set -e

# Determine shell and RC file
RC_FILE=""
case "$SHELL" in
  */zsh) RC_FILE="$HOME/.zshrc" ;;
  */bash) RC_FILE="$HOME/.bashrc" ;;
esac

if [ -z "$RC_FILE" ] || [ ! -f "$RC_FILE" ]; then
    echo "Could not detect active shell configuration file (.zshrc or .bashrc)."
    exit 0
fi

# Ensure we have the absolute path to the project root
# This script is located in scripts/, so we go up one level
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

update_alias() {
    local name="$1"
    local cmd="$2"
    local file="$3"

    # Check if the exact alias line already exists
    if ! grep -Fq "$cmd" "$file"; then
        # Remove old alias lines if present
        # We use a temp file to avoid issues with reading/writing same file
        grep -v "alias $name=" "$file" > "${file}.tmp" || true
        mv "${file}.tmp" "$file"
        
        # Append new alias
        echo "$cmd" >> "$file"
    fi
}

# 1. minerva-playbook
update_alias "minerva-playbook" "alias minerva-playbook='$PROJECT_DIR/scripts/minerva-playbook.sh'" "$RC_FILE"

# 2. minerva-wipe
update_alias "minerva-wipe" "alias minerva-wipe='$PROJECT_DIR/scripts/minerva-wipe.sh'" "$RC_FILE"