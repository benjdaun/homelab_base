#!/bin/bash

# Configuration
BASE_DIR=$(git rev-parse --show-toplevel)
VM_SET_FILE="$BASE_DIR/dev-env/multipass-vm-set.yml" # Path to the VM set file
CPUS=3                         # Number of CPUs per VM
MEMORY="7G"                    # RAM per VM
DISK="20G"                     # Disk space per VM
SSH_KEY="$HOME/.ssh/id_rsa_homelab.pub" # Path to your SSH public key
INVENTORY_FILE="$BASE_DIR/ansible/inventory/hosts.ini" # Ansible inventory file

# Check if yq is installed
if ! command -v yq &> /dev/null; then
  echo "yq is not installed. Please install it and try again."
  exit 1
fi

# Check if Multipass is installed
if ! command -v multipass &> /dev/null; then
  echo "Multipass is not installed. Please install it and try again."
  exit 1
fi

# Check if SSH key exists
if [ ! -f "$SSH_KEY" ]; then
  echo "SSH public key not found at $SSH_KEY. Please ensure it exists."
  exit 1
fi

# Read the number of VMs from the VM set file
NUM_MASTERS=$(yq e '.servers.quantity' "$VM_SET_FILE")
NUM_AGENTS=$(yq e '.agents.quantity' "$VM_SET_FILE")

# Create and configure master VMs
for ((i=1; i<=NUM_MASTERS; i++)); do
  VM="master-$i"
  
  # Check if VM already exists
  if multipass info "$VM" &>/dev/null; then
    echo "$VM already exists – skipping launch."
  else
    echo "Launching $VM..."
    multipass launch --name "$VM" --cpus "$CPUS" --memory "$MEMORY" --disk "$DISK"
  fi

  # Configure SSH access (only if VM was just created or needs reconfiguration)
  if ! multipass exec "$VM" -- test -f /home/ubuntu/.ssh/authorized_keys 2>/dev/null || ! grep -q "$(cat "$SSH_KEY" | cut -d' ' -f2)" <(multipass exec "$VM" -- cat /home/ubuntu/.ssh/authorized_keys 2>/dev/null); then
    echo "Configuring SSH access for $VM..."
    multipass exec "$VM" -- mkdir -p /home/ubuntu/.ssh
    multipass exec "$VM" -- bash -c "echo '$(cat "$SSH_KEY")' >> /home/ubuntu/.ssh/authorized_keys"
    multipass exec "$VM" -- chown -R ubuntu:ubuntu /home/ubuntu/.ssh
    multipass exec "$VM" -- chmod 600 /home/ubuntu/.ssh/authorized_keys
  else
    echo "SSH access already configured for $VM"
  fi

  # Fetch the IP address
  IP=$(multipass info "$VM" | grep IPv4 | awk '{print $2}')
  echo "$VM is running at $IP"

  # Add the VM to known_hosts (if not already present)
  if ! grep -q "$IP" "$HOME/.ssh/known_hosts" 2>/dev/null; then
    echo "Adding $VM to known_hosts..."
    ssh-keyscan -H "$IP" >> "$HOME/.ssh/known_hosts"
  fi

  # Verify SSH connectivity
  echo "Verifying SSH connectivity for $VM..."
  ssh -o "StrictHostKeyChecking=no" ubuntu@"$IP" "echo Connection successful!"
done

# Create and configure agent VMs
for ((i=1; i<=NUM_AGENTS; i++)); do
  VM="agent-$i"
  
  # Check if VM already exists
  if multipass info "$VM" &>/dev/null; then
    echo "$VM already exists – skipping launch."
  else
    echo "Launching $VM..."
    multipass launch --name "$VM" --cpus "$CPUS" --memory "$MEMORY" --disk "$DISK"
  fi

  # Configure SSH access (only if VM was just created or needs reconfiguration)
  if ! multipass exec "$VM" -- test -f /home/ubuntu/.ssh/authorized_keys 2>/dev/null || ! grep -q "$(cat "$SSH_KEY" | cut -d' ' -f2)" <(multipass exec "$VM" -- cat /home/ubuntu/.ssh/authorized_keys 2>/dev/null); then
    echo "Configuring SSH access for $VM..."
    multipass exec "$VM" -- mkdir -p /home/ubuntu/.ssh
    multipass exec "$VM" -- bash -c "echo '$(cat "$SSH_KEY")' >> /home/ubuntu/.ssh/authorized_keys"
    multipass exec "$VM" -- chown -R ubuntu:ubuntu /home/ubuntu/.ssh
    multipass exec "$VM" -- chmod 600 /home/ubuntu/.ssh/authorized_keys
  else
    echo "SSH access already configured for $VM"
  fi

  # Fetch the IP address
  IP=$(multipass info "$VM" | grep IPv4 | awk '{print $2}')
  echo "$VM is running at $IP"

  # Add the VM to known_hosts (if not already present)
  if ! grep -q "$IP" "$HOME/.ssh/known_hosts" 2>/dev/null; then
    echo "Adding $VM to known_hosts..."
    ssh-keyscan -H "$IP" >> "$HOME/.ssh/known_hosts"
  fi

  # Verify SSH connectivity
  echo "Verifying SSH connectivity for $VM..."
  ssh -o "StrictHostKeyChecking=no" ubuntu@"$IP" "echo Connection successful!"
done

# Build the inventory file safely with current IPs
echo "Building Ansible inventory file..."
echo "[master]" > "$INVENTORY_FILE"
for VM in $(multipass list --format csv | awk -F, '/master-/{print $1}'); do
  if [ -n "$VM" ]; then
    IP=$(multipass info "$VM" | grep IPv4 | awk '{print $2}')
    echo "$IP node_name=$VM ansible_user=ubuntu ansible_ssh_private_key_file=$HOME/.ssh/id_rsa_homelab net_interface=ens3" >> "$INVENTORY_FILE"
  fi
done

echo "[agent]" >> "$INVENTORY_FILE"
for VM in $(multipass list --format csv | awk -F, '/agent-/{print $1}'); do
  if [ -n "$VM" ]; then
    IP=$(multipass info "$VM" | grep IPv4 | awk '{print $2}')
    echo "$IP node_name=$VM ansible_user=ubuntu ansible_ssh_private_key_file=$HOME/.ssh/id_rsa_homelab net_interface=ens3" >> "$INVENTORY_FILE"
  fi
done

echo -e "\nAnsible inventory file created at $INVENTORY_FILE:"
cat "$INVENTORY_FILE"
