#!/usr/bin/env bash
set -euo pipefail

# install-rke.sh
# Usage: install-rke.sh <master-ip> <worker1-ip> <worker2-ip> [--user USER] [--ssh-key KEY_PATH] [--rke-version VERSION]

show_help() {
  cat <<EOF
Usage: $0 MASTER_IP WORKER1_IP WORKER2_IP [--user USER] [--ssh-key KEY_PATH] [--rke-version VERSION]

Installs Docker on the target nodes, generates an RKE cluster config, downloads RKE, and runs 'rke up'.

Defaults:
  USER: ubuntu
  SSH_KEY: ~/.ssh/id_rsa
  RKE_VERSION: v1.3.13

EOF
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  show_help
  exit 0
fi

if [[ $# -lt 3 ]]; then
  echo "Error: At least 3 IPs (master and 2 workers) are required."
  show_help
  exit 1
fi

MASTER_IP=$1; shift
WORKER1_IP=$1; shift
WORKER2_IP=$1; shift

USER=ubuntu
SSH_KEY="$HOME/.ssh/id_rsa"
RKE_VERSION="v1.3.13"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user)
      USER="$2"; shift 2;;
    --ssh-key)
      SSH_KEY="$2"; shift 2;;
    --rke-version)
      RKE_VERSION="$2"; shift 2;;
    -h|--help)
      show_help; exit 0;;
    *)
      echo "Unknown arg: $1"; show_help; exit 1;;
  esac
done

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 -i $SSH_KEY"

install_docker_remote() {
  local ip=$1
  echo "Installing Docker on ${ip} as ${USER}..."
  ssh ${SSH_OPTS} ${USER}@${ip} bash -s <<'REMOTE'
set -eux
if [ -f /etc/os-release ]; then
  . /etc/os-release
fi
if command -v docker >/dev/null 2>&1; then
  echo "Docker already installed"
  exit 0
fi
if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg lsb-release
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
else
  # Fallback to get.docker.com script for other distros
  curl -fsSL https://get.docker.com | sudo sh
fi
sudo systemctl enable --now docker
REMOTE
}

for ip in "$MASTER_IP" "$WORKER1_IP" "$WORKER2_IP"; do
  install_docker_remote "$ip"
done

WORKDIR=$(mktemp -d)
pushd "$WORKDIR" >/dev/null

echo "Preparing RKE binary (version: ${RKE_VERSION})..."
RKE_BIN="rke"
if [[ ! -f "$RKE_BIN" ]]; then
  curl -fsSL -o "$RKE_BIN" "https://github.com/rancher/rke/releases/download/${RKE_VERSION}/rke_linux-amd64"
  chmod +x "$RKE_BIN"
fi

cat > cluster.yml <<EOF
nodes:
  - address: ${MASTER_IP}
    user: ${USER}
    role: [controlplane,etcd]
    ssh_key_path: ${SSH_KEY}
  - address: ${WORKER1_IP}
    user: ${USER}
    role: [worker]
    ssh_key_path: ${SSH_KEY}
  - address: ${WORKER2_IP}
    user: ${USER}
    role: [worker]
    ssh_key_path: ${SSH_KEY}
services: {}
EOF

echo "Generated cluster.yml:
$(cat cluster.yml)"

echo "Running RKE up (this will create kube_config_cluster.yml)..."
./${RKE_BIN} up --config cluster.yml

if [[ -f kube_config_cluster.yml ]]; then
  mv kube_config_cluster.yml ../../merged-kubeconfig-rke || true
  echo "Kubeconfig saved to merged-kubeconfig-rke"
else
  echo "RKE did not produce kube_config_cluster.yml — check output above"
fi

popd >/dev/null

echo "Done."
