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
- Sample microservices deployment via Helm

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
├── manifests/              # Raw Kubernetes YAML (fallback / examples)
├── docs/                   # Architecture diagrams, decision logs
├── scripts/                # Utility scripts (kubeconfig merge, context switch…)
└── README.md
