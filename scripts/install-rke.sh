#!/bin/bash
# Usage: 
# For Master: sudo ./install_rke2.sh --master
# For Worker: sudo ./install_rke2.sh <MASTER_IP> <NODE_TOKEN>

ARG1=$1
TOKEN=$2

# 1. Safety Check & System Prep
if [ -z "$ARG1" ]; then
    echo "ERROR: No arguments provided."
    echo "Usage (Master): $0 --master"
    echo "Usage (Worker): $0 <MASTER_IP> <NODE_TOKEN>"
    exit 1
fi

swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
mkdir -p /etc/rancher/rke2/

# 2. Installation Logic
if [ "$ARG1" == "--master" ]; then
    echo "--- [CONFIRMED] Installing RKE2 SERVER (Master) ---"
        
    curl -sfL https://get.rke2.io | sh -
    systemctl enable rke2-server.service --now
    
    echo "Waiting for token generation..."
    until [ -f /var/lib/rancher/rke2/server/node-token ]; do sleep 2; done
    
    echo "Your Node Token is: $(cat /var/lib/rancher/rke2/server/node-token)"
    
    # Setup Kubectl
    mkdir -p $HOME/.kube
    cp /etc/rancher/rke2/rke2.yaml $HOME/.kube/config
    export PATH=$PATH:/var/lib/rancher/rke2/bin/
    echo 'export PATH=$PATH:/var/lib/rancher/rke2/bin/' >> ~/.bashrc && source ~/.bashrc

elif [ -n "$ARG1" ] && [ -n "$TOKEN" ]; then
    echo "--- Installing RKE2 AGENT (Worker) ---"
    MASTER_IP=$ARG1
    
    echo "server: https://${MASTER_IP}:9345" > /etc/rancher/rke2/config.yaml
    echo "token: ${TOKEN}" >> /etc/rancher/rke2/config.yaml
    
    curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sh -
    systemctl enable rke2-agent.service --now
else
    echo "ERROR: Worker installation requires both Master IP and Token."
    exit 1
fi