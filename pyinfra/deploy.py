from pyinfra import host, inventory
from pyinfra.operations import apt, files, server, systemd
from pyinfra.facts.server import Whoami
import os
import random
import string

# Unique hash for this execution
if host.group == 'local':
    unique_hash = ''.join(random.choice(string.hexdigits.lower()) for _ in range(5))
    print(f"Unique hash for this execution: {unique_hash}")
    host.data.unique_hash = unique_hash
else:
    unique_hash = inventory.get_host('localhost').data.get('unique_hash')

# Determine first master IP
master_hosts = inventory.get_group('master')
first_master = master_hosts[0]
first_master_ip = inventory.get_host(first_master).host

# Calculate keepalived virtual IP (add 2 to last octet)
parts = first_master_ip.split('.')
parts[-1] = str(int(parts[-1]) + 2)
keepalived_vip = '.'.join(parts)

# Install open-iscsi on all hosts except localhost
if host.name != 'localhost':
    apt.packages(name="Install open-iscsi", packages=['open-iscsi'], sudo=True)
    systemd.service(name="Enable iscsid", service="iscsid", enabled=True, running=True, sudo=True)

# K3s server role
if host.group == 'master':
    apt.packages(name="Install keepalived", packages=['keepalived'], sudo=True)
    files.template(
        src='templates/keepalived.conf.j2',
        dest='/etc/keepalived/keepalived.conf',
        keepalived_vip=keepalived_vip,
        net_interface=host.data.net_interface,
        inventory_hostname=host.name,
        groups=inventory.get_group('master'),
        sudo=True,
    )
    systemd.service(name="Restart keepalived", service="keepalived", restarted=True, sudo=True)

    if host.name == first_master:
        server.shell(
            name="Install K3s server",
            commands=[
                f"curl -sfL https://get.k3s.io | sh -s - server --cluster-init --advertise-address={first_master_ip} --node-ip {first_master_ip} --tls-san={keepalived_vip} --disable traefik --disable servicelb --node-label dev --node-name {host.data.node_name}"
            ],
            sudo=True,
        )

        files.get(
            src='/etc/rancher/k3s/k3s.yaml',
            dest=os.path.join(host.data.project_dir, 'kubeconfigs', os.environ.get('ENV', 'dev'), f'{unique_hash}-kubeconfig'),
            sudo=True,
        )

        files.line(
            path=os.path.join(host.data.project_dir, 'kubeconfigs', os.environ.get('ENV', 'dev'), f'{unique_hash}-kubeconfig'),
            search='https://127.0.0.1:6443',
            replace=f'https://{keepalived_vip}:6443',
        )

        result = server.shell('cat /var/lib/rancher/k3s/server/token', sudo=True)
        host.data.k3s_cluster_token = result.stdout.strip()
    else:
        token = inventory.get_host(first_master).data.get('k3s_cluster_token')
        server.shell(
            name="Join additional server",
            commands=[
                f"curl -sfL https://get.k3s.io | K3S_TOKEN={token} sh -s - server --server https://{keepalived_vip}:6443 --node-name {host.data.node_name}"
            ],
            sudo=True,
        )

# K3s agent role
if host.group == 'agent':
    token = inventory.get_host(first_master).data.get('k3s_cluster_token')
    server.shell(
        name="Join agent to the cluster",
        commands=[
            f"curl -sfL https://get.k3s.io | K3S_TOKEN={token} sh -s - agent --server https://{first_master_ip}:6443"
        ],
        sudo=True,
    )

# Apply Gateway API CRDs on localhost
if host.group == 'local':
    kubeconfig = os.path.join(inventory.get_host('localhost').data.get('project_dir', '/tmp'), 'kubeconfigs', os.environ.get('ENV', 'dev'), f'{unique_hash}-kubeconfig')
    server.shell(
        commands=[
            f"export KUBECONFIG={kubeconfig}",
            "kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.1.0/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml",
            "kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.1.0/config/crd/standard/gateway.networking.k8s.io_gateways.yaml",
            "kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.1.0/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml",
            "kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.1.0/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml",
            "kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.1.0/config/crd/standard/gateway.networking.k8s.io_grpcroutes.yaml",
            "kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.1.0/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml",
        ],
    )

