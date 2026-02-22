# Infrastructure Repo: Hybrid Kubernetes Deployment with Proxmox, RKE, and AWS EKS

## Overview

This repository provides a comprehensive infrastructure-as-code (IaC) solution for setting up a **hybrid Kubernetes environment**. It enables the deployment of microservices applications across **on-premise** and **cloud** infrastructures.

- **On-premise**: Proxmox VE (virtualization) + Rancher Kubernetes Engine (RKE)
- **Cloud**: AWS Elastic Kubernetes Service (EKS)

The architecture supports:
- Local development & cost-sensitive workloads on-prem
- Production scaling, HA, and bursting in AWS
- Workload portability and disaster recovery between environments

Tools used: Terraform, Ansible, Helm, kubectl, Rancher (optional), ArgoCD (future).

## Key Features

### On-Premise
- Automated Proxmox VE installation & configuration
- RKE cluster deployment on Proxmox VMs
- Local storage (Ceph / ZFS / local), networking, load balancing
- meiot microservices deployment via Helm

### Cloud
- AWS EKS cluster with best-practice VPC, subnets, node groups
- IRSA, Karpenter / Cluster Autoscaler support
- Integration with AWS services (ALB, EFS, RDS, S3, ...)

### Hybrid / Multi-cluster
- Multi-cluster visibility (via Rancher or Lens / kubectl contexts)
- Workload migration patterns
- GitOps-ready structure (ArgoCD / Flux future)
- Unified observability foundation (Prometheus + Grafana + Loki)

### Security & Operations
- RBAC, Network Policies, Pod Security Standards
- Secrets management (Vault / AWS Secrets Manager / Sealed Secrets)
- Backup & DR recommendations
- Cost tagging & alerting hooks

## Folder Structure (proposed)

```text
.
├── ansible/                # RKE & Proxmox configuration playbooks
├── terraform/
│   ├── on-prem/            # Proxmox + RKE infrastructure
│   └── cloud/              # AWS EKS + supporting resources
├── helm/                   # Helm charts for microservices & observability
├── manifests/              # Raw Kubernetes YAML (fallback / meiots)
├── docs/                   # Architecture diagrams, decision logs
├── scripts/                # Utility scripts (kubeconfig merge, context switch…)
└── README.md
```

## Quick Start: Deploy On-Premise RKE Cluster with Longhorn

### Prerequisites

- Proxmox VE server with API access
- Terraform, Ansible, kubectl, helm installed locally
- SSH key for VM access (default: ~/.ssh/id_rsa)
- Minimum 12 vCPUs and 16GB RAM available on Proxmox

### Step 1: Create 3 VMs on Proxmox via Terraform

```bash
cd terraform/on-prem
cp terraform.tfvars.example terraform.tfvars  # Update with your Proxmox credentials and details

terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Note the 3 VM IPs from output
terraform output vm_ips
```

**Files updated:**
- `terraform/on-prem/main.tf` — 3 VMs with 2 cores, 4GB RAM, 40GB disk
- `terraform/on-prem/variables.tf` — Proxmox credentials and VM sizing

### Step 2: Deploy RKE Cluster via Ansible

```bash
cd ../../ansible

# Install Ansible collections first
ansible-galaxy collection install -r requirements.yml

# Update inventory with your VM IPs
vi inventory/hosts.ini
# Replace IPs in [rke_nodes] group with outputs from Step 1

# Deploy RKE cluster (installs Docker, runs 'rke up')
ansible-playbook -i inventory/hosts.ini rke.yml -v
```

**What it does:**
- Installs Docker CE on all 3 nodes
- Disables swap
- Downloads RKE binary (v1.3.13)
- Generates cluster config and runs `rke up`
- Saves kubeconfig to `merged-kubeconfig-rke`

**Verify cluster:**
```bash
export KUBECONFIG=merged-kubeconfig-rke
kubectl get nodes  # Should show 3 Ready nodes
```

### Step 3: Install Longhorn Storage & Nginx Ingress

```bash
# Ensure KUBECONFIG is set
export KUBECONFIG=$(pwd)/merged-kubeconfig-rke

# Deploy Longhorn and Nginx Ingress Controller
ansible-playbook -i inventory/hosts.ini longhorn-nginx.yml -v
```

**What it does:**
- Installs Longhorn (distributed block storage)
- Installs Nginx Ingress Controller with LoadBalancer service
- Creates Ingress to expose Longhorn UI at `longhorn.meiot.site`

**Access Longhorn UI:**
```bash
# Get Nginx LoadBalancer IP
kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx-controller

# Add to /etc/hosts
echo "<EXTERNAL-IP> longhorn.meiot.site" >> /etc/hosts

# Open browser
open http://longhorn.meiot.site
```

### Step 4: Verify Everything

```bash
# Check all nodes
kubectl get nodes -o wide

# Check Longhorn pods
kubectl get pod -n longhorn-system

# Check Nginx pods
kubectl get pod -n ingress-nginx

# Verify storage class
kubectl get storageclass
```

## Next Steps

- Deploy sample microservices using Helm charts in `helm/`
- Set up AWS EKS for cloud workloads (see `terraform/cloud/`)
- Configure observability: Prometheus, Grafana, Loki
- Implement backup policies in Longhorn
- Set up ArgoCD for GitOps continuous deployment

## Documentation

- **[INSTALLATION.md](INSTALLATION.md)** — Detailed installation & troubleshooting guide
- **[ansible/README.md](ansible/README.md)** — Ansible playbook reference
- **[terraform/on-prem/README.md](terraform/on-prem/README.md)** — Proxmox Terraform guide
- **[docs/](docs/)** — Architecture diagrams and design decisions
