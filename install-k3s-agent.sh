
# Download and install k3s as an agent using the official k3s script
curl -sfL https://get.k3s.io | K3S_URL="https://192.168.0.39:6443" K3S_NODE_NAME="beelink-gi5" K3S_TOKEN="$(bw get item k3s-token | jq -r '.login.password')" sh -
