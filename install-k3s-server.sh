#!/bin/bash

# Ensure the /etc/rancher/k3s directory exists
mkdir -p /etc/rancher/k3s

# Create your custom configuration file for k3s
# Disabling Traefik (will be installed separately using Helm)
cat <<EOF > /etc/rancher/k3s/config.yaml
write-kubeconfig-mode: "644"
disable:
  - traefik # Disable default Traefik installation
node-name: "macbook"
cluster-cidr: "10.42.0.0/16"
service-cidr: "10.43.0.0/16"
EOF

# Download and install k3s using the k3s install script
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -