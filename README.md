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

## Quick Start: Deploy AWS EKS Cluster

### What Gets Deployed

This Terraform configuration automates all steps needed for a production-ready EKS cluster:

1. ✅ **VPC & Subnets** — Creates VPC, public subnets (for load balancers), private subnets (for nodes), NAT gateways, and route tables
2. ✅ **IAM Roles** — Automatically creates and configures IAM roles for the EKS cluster and worker nodes
3. ✅ **EKS Control Plane** — Provisions the managed EKS control plane (the "brain")
4. ✅ **Node Groups** — Provisions EC2 instances as worker nodes (the "body"), with auto-scaling
5. ✅ **kubectl Configuration** — Outputs commands to configure kubectl to talk to your cluster

### Prerequisites

- AWS account with appropriate IAM permissions
- Terraform installed locally
- AWS credentials configured (`aws configure` or environment variables)
- `kubectl` and `aws-cli` tools installed

### Step 1: Deploy EKS Cluster and VPC via Terraform

```bash
cd terraform/cloud

# Initialize Terraform
terraform init

# Plan the deployment (review VPC, subnets, EKS cluster resources)
terraform plan \
  -var="cluster_name=meiot-eks" \
  -var="cluster_version=1.28" \
  -var="vpc_cidr=10.0.0.0/16" \
  -var="single_nat_gateway=true" \
  -out=tfplan

# Apply the plan to create resources in AWS
terraform apply tfplan
```

**What it does:**
- Creates VPC with public & private subnets across 3 availability zones
- Configures NAT Gateway for private subnet egress
- Provisions EKS control plane and managed node group
- Sets up all networking, IAM roles, and security groups

**Output:**
```bash
# Get cluster information
terraform output cluster_name
terraform output cluster_endpoint
terraform output cluster_id
```

### Step 2: Configure kubectl to Talk to Your Cluster

```bash
# Use the Terraform output command to get the kubectl configuration command
terraform output kubectl_config_command

# Or manually run:
aws eks update-kubeconfig \
  --region us-east-1 \
  --name meiot-eks

# Verify kubectl can communicate with the cluster
kubectl cluster-info
kubectl get nodes
```

**Variables you can customize:**
- `vpc_cidr` — VPC CIDR block (default: `10.0.0.0/16`)
- `private_subnet_cidrs` — Private subnet ranges (default: `10.0.1.0/24`, `10.0.2.0/24`, `10.0.3.0/24`)
- `public_subnet_cidrs` — Public subnet ranges (default: `10.0.101.0/24`, `10.0.102.0/24`, `10.0.103.0/24`)
- `single_nat_gateway` — Use one NAT Gateway for all subnets (default: `true`, cost-effective)
- `node_instance_type` — EC2 instance type for nodes (default: `t3.micro`, free-tier eligible)
- `node_desired_capacity` — Number of worker nodes (default: `1`)
- `cluster_version` — Kubernetes version (default: `1.28`)

### Step 3: Verify EKS Cluster
- `vpc_cidr` — VPC CIDR block (default: `10.0.0.0/16`)
- `private_subnet_cidrs` — Private subnet ranges (default: `10.0.1.0/24`, `10.0.2.0/24`, `10.0.3.0/24`)
- `public_subnet_cidrs` — Public subnet ranges (default: `10.0.101.0/24`, `10.0.102.0/24`, `10.0.103.0/24`)
- `single_nat_gateway` — Use one NAT Gateway for all subnets (default: `true`, cost-effective)
- `node_instance_type` — EC2 instance type for nodes (default: `t3.micro`, free-tier eligible)
- `node_desired_capacity` — Number of worker nodes (default: `1`)

### Step 3: Verify EKS Cluster

```bash
# Check cluster nodes
kubectl get nodes -o wide

# Check node readiness
kubectl get nodes

# View cluster info
kubectl cluster-info

# Check default storage class
kubectl get storageclass
```

### Step 4: (Optional) Deploy Applications

Once the cluster is running, you can deploy applications using Helm charts from `helm/` or Kubernetes manifests from `manifests/`.

```bash
# Example: Deploy a sample app
kubectl apply -f manifests/example-deployment.yaml
```

### Step 5: Cleanup: Destroy EKS Cluster

```bash
# Remove all Kubernetes resources first
kubectl delete --all deployments
kubectl delete --all services
kubectl delete --all pvc

# Then destroy Terraform resources
cd terraform/cloud
terraform destroy
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
