#!/bin/bash
# Simple script to prepare a new node and assign a static IP without rebooting

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

if [ $# -lt 4 ]; then
  echo "Usage: $0 <hostname> <interface> <ip-address> <gateway> [dns]"
  exit 1
fi

HOSTNAME="$1"
INTERFACE="$2"
STATIC_IP="$3"
GATEWAY="$4"
DNS="${5:-8.8.8.8}"

# Set the hostname
hostnamectl set-hostname "$HOSTNAME"

# Configure a static IP using netplan and apply it immediately
NETPLAN_FILE=/etc/netplan/01-homelab-static.yaml
cat > "$NETPLAN_FILE" <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      dhcp4: no
      addresses:
        - $STATIC_IP
      gateway4: $GATEWAY
      nameservers:
        addresses: [$DNS]
EOF

netplan apply

# Display MAC address of the configured interface
echo "\nConfigured interface $INTERFACE has MAC address:"
ip -o link show "$INTERFACE" | awk -F' ' '/link\/ether/ {print $2}'
echo "\nStatic IP $STATIC_IP has been applied without reboot"
