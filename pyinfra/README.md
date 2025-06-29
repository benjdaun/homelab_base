# pyinfra Deployment

This folder contains pyinfra code that mirrors the original Ansible playbooks.

## Requirements

- Python 3
- `pyinfra` package installed (`pip install pyinfra`)

## Usage

Run the deployment from this directory:

```bash
pyinfra hosts.ini deploy.py
```

The inventory file (`hosts.ini`) uses the same layout as the previous Ansible configuration. The `deploy.py` script performs the K3s server/agent setup, configures `keepalived`, and installs common packages on all hosts.
