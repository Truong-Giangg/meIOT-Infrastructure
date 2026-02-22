# Architecture Notes

This document contains starter notes for the hybrid Kubernetes architecture described in README.md.

- On-prem: Proxmox + RKE. Use the Terraform files in `terraform/on-prem` and Ansible playbooks in `ansible/`.
- Cloud: AWS EKS. Use the Terraform files in `terraform/cloud` to provision VPC and EKS.

Fill these files with concrete modules and variables for your environment.
