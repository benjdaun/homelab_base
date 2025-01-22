#!/bin/bash

# Wrapper script to execute ansible-playbook with a specified inventory file
if [ -z "$1" ]; then
  echo "Usage: $0 <inventory_file>"
  exit 1
fi

INVENTORY_FILE="$1"
ENVIRONMENT="$2"
PLAYBOOK_FILE="playbook.yml"

# Check if inventory file exists
if [ ! -f "$INVENTORY_FILE" ]; then
  echo "Error: Inventory file '$INVENTORY_FILE' not found."
  exit 1
fi

# Execute the ansible-playbook command
ansible-playbook -i "$INVENTORY_FILE" "$PLAYBOOK_FILE" -K \
-e "inventory_file=$INVENTORY_FILE" \
-e "unique_hash=$(cat $INVENTORY_FILE | sha256sum | cut -c1-5) \
-e env=$ENVIRONMENT"
