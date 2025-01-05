#!/bin/bash

# Configuration
VM_NAMES=("vm1" "vm2" "vm3")   # Names of the VMs
CPUS=3                         # Number of CPUs per VM
MEMORY="7G"                    # RAM per VM
DISK="20G"                     # Disk space per VM
SSH_KEY="$HOME/.ssh/id_rsa_homelab.pub" # Path to your SSH public key
INVENTORY_FILE="/home/benjdaun/homelab_base/ansible/ansible2/inventory/hosts.ini" # Ansible inventory file

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

# Prepare the inventory file
echo "[master]" > "$INVENTORY_FILE"

# Create and configure each VM
for VM in "${VM_NAMES[@]}"; do
  echo "Launching $VM..."
  multipass launch --name "$VM" --cpus "$CPUS" --memory "$MEMORY" --disk "$DISK"

  echo "Configuring SSH access for $VM..."
  multipass exec "$VM" -- mkdir -p /home/ubuntu/.ssh
  multipass exec "$VM" -- bash -c "echo '$(cat "$SSH_KEY")' >> /home/ubuntu/.ssh/authorized_keys"
  multipass exec "$VM" -- chown -R ubuntu:ubuntu /home/ubuntu/.ssh
  multipass exec "$VM" -- chmod 600 /home/ubuntu/.ssh/authorized_keys

  # Fetch the IP address
  IP=$(multipass info "$VM" | grep IPv4 | awk '{print $2}')
  echo "$VM is running at $IP"

  # Add the VM to known_hosts
  echo "Adding $VM to known_hosts..."
  ssh-keyscan -H "$IP" >> "$HOME/.ssh/known_hosts"

  # Verify SSH connectivity
  echo "Verifying SSH connectivity for $VM..."
  ssh -o "StrictHostKeyChecking=no" ubuntu@"$IP" "echo Connection successful!"

  # Add the VM to the inventory file
  echo "$IP ansible_user=ubuntu ansible_ssh_private_key_file=$HOME/.ssh/id_rsa_homelab" >> "$INVENTORY_FILE"
done

echo -e "\nAnsible inventory file created at $INVENTORY_FILE:"
cat "$INVENTORY_FILE"
