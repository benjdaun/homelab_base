# Homelab Base

This repository is designed to facilitate the setup and management of a Kubernetes-based homelab environment. It leverages a combination of Ansible, Helm, and Terraform to deploy and configure various applications and services on a Kubernetes cluster.

## Project Structure

The project is organized into several key directories, each serving a specific purpose:

- **ansible**: Contains Ansible playbooks and roles for installing and configuring K3s server and agent. Key files include `install_k3s.yaml`, `inventory.ini`, and `cilium-values.yaml`.

- **base-applications**: Includes YAML files for deploying various applications like Bitwarden, Cert-Manager, and Postgres-Operator.

- **configuration**: Holds configuration files for various applications, such as `cert-manager-values.yaml`, `external-dns-values.yaml`, `prometheus-values.yaml`, and `traefik-values.yaml`.

- **crd-resources**: Contains Custom Resource Definitions (CRDs) and other related resources for Kubernetes. Key files include `argo-httproute.yaml`, `cluster-issuer.yaml`, and `cluster-secret-store.yaml`.

- **downloaded-charts**: Contains downloaded Helm charts for various applications.

- **terraform**: Contains Terraform configuration files and scripts for managing infrastructure resources. Key files include `argocd-values.yaml`, `base-application.yaml`, `main.tf`, `providers.tf`, and `variables.tf`.

## Getting Started

### Prerequisites

- **Helm**: Ensure Helm is installed to manage Kubernetes applications.
- **Ansible**: Required for executing playbooks to configure the K3s cluster.
- **Terraform**: Used for infrastructure management and provisioning.

### Installation

1. **Install K3s**: Use the Ansible playbooks in the `ansible` directory to set up the K3s server and agent.

2. **Install Argo CD**: The first thing to be installed on the cluster is Argo CD, along with the root application, and some secrets tooling.

3. **Install Core Applications**: Argo CD pulls the contents of the base-applications and CRD resources into the cluster. These are kind of like a "platform" that just supply prerequisites to get things running nicely, like certificates, DNS, redundant storage, etc.

### Assigning Static IP Addresses

Each node should keep the same IP address across reboots. You can configure this directly on the node without touching the router:

1. Choose an unused IP address and know your network gateway (for example `192.168.1.1`).
2. Run the helper script `setup-new-node.sh` with sudo to set the hostname, update packages, and apply the static address immediately:

```bash
sudo ./setup-new-node.sh <hostname> <interface> <ip-address> <gateway> [dns]
```

The script writes a small netplan file at `/etc/netplan/01-homelab-static.yaml` and runs `netplan apply` so the IP change is effective right away. It also prints the MAC address of the interface for reference.


## External Dependencies

The premise of this project is to host everything in self-contained hardware as a means of learning how to build systems from the ground up. If service providers can make some of this easier by hosting parts of the stack, fantastic. However, they shouldn't be used as "magic" that couldn't be replicated "on-prem", if required. For example, the monitoring solution should be offloaded to Grafana Cloud, but that would defeat the purpose of learning how to run it well, including managing the lifecycle of the data gathered.

There are 2 exceptions to this philosophy.

1. **Secrets**: A personal Bitwarden account is used as a secrets vault. This is good enough to get started and requires low setup effort. However, the major vulnerability is that it requires the master password to be a k8s secret present in the cluster. A malicious actor who gains access to this would gain access to the entire Bitwarden account.

This should be replaced by an AWS secrets manager setup or something similar.

2. **DNS**: This setup uses Cloudflare DNS because that's where I happened to purchase my domain. You can totally run a Bind9 server on a local single board computer as a private DNS solution. However, I don't currently have an "always on" piece of hardware, and am loath to introduce a single point of failure for something so trivial.



