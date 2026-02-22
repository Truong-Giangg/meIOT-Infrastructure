# RKE, Longhorn & Nginx Ingress Installation Guide

This guide covers installing a 3-node RKE cluster (1 master, 2 workers) with Longhorn storage and Nginx Ingress Controller.

## Prerequisites

- 3 VMs created via Terraform (see `terraform/on-prem/main.tf`)
- Terraform applies successfully and produces 3 VM IPs
- SSH key configured and accessible
- `kubectl`, `helm`, and `rke` binaries installed locally

## Installation Steps

### 1. Create VMs via Terraform

```bash
cd terraform/on-prem
terraform init
terraform plan -out=tfplan
terraform apply tfplan
# Note the 3 VM IPs from output
```

### 2. Install RKE Cluster

```bash
cd scripts

# Run the installation script with your VM IPs
./install-rke.sh <MASTER_IP> <WORKER1_IP> <WORKER2_IP>

# Example:
# ./install-rke.sh 192.168.1.100 192.168.1.101 192.168.1.102

# This will:
# - Install Docker on all 3 nodes
# - Generate cluster.yml for RKE
# - Run 'rke up'
# - Save kubeconfig to merged-kubeconfig-rke
```

### 3. Verify Cluster is Ready

```bash
export KUBECONFIG=merged-kubeconfig-rke
kubectl get nodes
# Should show 3 nodes in Ready state (may take 1-3 minutes)
```

### 4. Install Longhorn & Nginx Ingress

```bash
./install-longhorn-nginx.sh \
  --kubeconfig merged-kubeconfig-rke \
  --longhorn-domain longhorn.local

# This will:
# - Install Longhorn for distributed storage
# - Install Nginx Ingress Controller
# - Create an Ingress to expose Longhorn UI
```

### 5. Access Longhorn UI

Get the Nginx LoadBalancer IP:
```bash
kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx-controller -o wide
# Note the EXTERNAL-IP
```

Add to your `/etc/hosts`:
```
<EXTERNAL-IP> longhorn.local
```

Then open http://longhorn.local in your browser.

## Verification Commands

```bash
# Check all nodes are ready
kubectl get nodes

# Check Longhorn pods
kubectl get pod -n longhorn-system

# Check Nginx pods
kubectl get pod -n ingress-nginx

# Check Ingress
kubectl get ingress -n longhorn-system

# Check Longhorn storage class
kubectl get storageclass

# Test by creating a PVC
kubectl create pvc test-pvc --size=1Gi --storageclass=longhorn --dry-run=client -o yaml | kubectl apply -f -
kubectl get pvc -A
```

## Troubleshooting

### Longhorn pods not starting
```bash
kubectl describe pod -n longhorn-system <pod-name>
kubectl logs -n longhorn-system <pod-name>
```

### Nginx Ingress not getting External IP
```bash
# Check if MetalLB or similar is configured for LoadBalancer
kubectl get svc -n ingress-nginx
# If pending, may need to use NodePort instead:
# Edit the install script to use --set controller.service.type=NodePort
```

### Cannot resolve longhorn.local
- Ensure DNS resolver is using your /etc/hosts
- Or use the IP directly: `kubectl get ingress -n longhorn-system -o wide`

## Next Steps

- Deploy sample microservices using the Helm charts in `helm/`
- Set up ArgoCD for GitOps continuous deployment
- Configure monitoring/observability (Prometheus, Grafana)
- Add backup/restore policies in Longhorn
