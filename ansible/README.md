# Ansible Playbooks for meIOT Infrastructure

This folder contains Ansible playbooks to automate the deployment of RKE clusters and install supporting infrastructure (Longhorn, Nginx Ingress).

## Prerequisites

- Ansible 2.9+ installed locally
- kubectl, helm installed locally
- Python 3.6+ with `requests` library
- SSH access to target nodes with key-based authentication
- Docker knowledge (basic understanding of containerization)

## Installation

### 1. Install Ansible and Required Collections

```bash
# Install Ansible (if not already installed)
pip install ansible>=2.9.0

# Install required Ansible collections
ansible-galaxy collection install -r requirements.yml
```

### 2. Configure Inventory

Edit `inventory/hosts.ini` with your environment details:

```ini
[rke_nodes]
rke-master ansible_host=192.168.1.100 ansible_user=ubuntu node_role=master
rke-worker1 ansible_host=192.168.1.101 ansible_user=ubuntu node_role=worker
rke-worker2 ansible_host=192.168.1.102 ansible_user=ubuntu node_role=worker

[rke_nodes:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

Replace IPs, hostnames, users, and SSH key path with your actual values.

## Usage

### Deploy RKE Cluster

```bash
# Install Docker on all nodes and deploy RKE cluster
ansible-playbook -i inventory/hosts.ini rke.yml -v

# Or with specific tags
ansible-playbook -i inventory/hosts.ini rke.yml --tags "docker" -v
```

This playbook:
1. Installs Docker on all RKE nodes
2. Disables swap
3. Downloads and runs RKE binary
4. Generates kubeconfig at `merged-kubeconfig-rke`
5. Validates cluster connectivity

### Install Longhorn and Nginx Ingress

```bash
# Set KUBECONFIG environment variable
export KUBECONFIG=/path/to/merged-kubeconfig-rke

# Install Longhorn and Nginx Ingress Controller
ansible-playbook -i inventory/hosts.ini longhorn-nginx.yml -v

# Or specify kubeconfig inline
ansible-playbook longhorn-nginx.yml \
  -e "kubeconfig=/path/to/merged-kubeconfig-rke" \
  -e "longhorn_domain=longhorn.yourdomain.com" \
  -v
```

This playbook:
1. Adds Helm repositories (Longhorn, Nginx Ingress)
2. Creates namespaces (longhorn-system, ingress-nginx)
3. Installs Longhorn with replication factor of 2
4. Installs Nginx Ingress Controller with LoadBalancer service type
5. Creates Ingress to expose Longhorn UI
6. Waits for all pods to be Ready
7. Displays access information

## Playbook Details

### rke.yml

**Two plays:**

1. **Install RKE Prerequisites** (hosts: rke_nodes)
   - Installs Docker CE, containerd, and CLI tools
   - Disables swap
   - Verifies Docker socket availability

2. **Deploy RKE Cluster** (hosts: localhost)
   - Downloads RKE binary
   - Generates cluster.yml from inventory
   - Runs `rke up`
   - Copies kubeconfig to project root
   - Tests cluster connectivity

**Variables:**
- `rke_version`: RKE version to deploy (default: v1.3.13)
- `kubeconfig_path`: Where to save kubeconfig (default: ../merged-kubeconfig-rke)

### longhorn-nginx.yml

**One play:** Install Longhorn and Nginx Ingress

**Variables:**
- `kubeconfig`: Path to kubeconfig (uses $KUBECONFIG env var or ~/.kube/config)
- `longhorn_domain`: Domain for Longhorn UI (default: longhorn.meiot.site)
- `nginx_version`: Nginx Ingress chart version (default: 4.8.0)

**Waits for:**
- Longhorn pods to be Ready
- Nginx Ingress deployment to have at least 1 ready replica
- Ingress resource to be applied

**Post-tasks:**
- Displays pod status
- Shows LoadBalancer service info
- Prints Longhorn UI access URL

## Inventory Variables

### RKE Nodes

Each host in `[rke_nodes]` should have:

- `ansible_host`: IP or hostname of the target node
- `ansible_user`: SSH username (e.g., ubuntu, centos)
- `node_role`: Either `master` or `worker` (determines RKE roles)
- `ansible_ssh_private_key_file`: Path to SSH private key
- `ansible_ssh_common_args`: SSH options (e.g., StrictHostKeyChecking)

### Group Variables

Set in `[rke_nodes:vars]`:

```ini
[rke_nodes:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
```

## Troubleshooting

### SSH Connection Issues

```bash
# Test SSH connectivity
ansible -i inventory/hosts.ini rke_nodes -m ping

# Verbose SSH debugging
ansible-playbook -i inventory/hosts.ini rke.yml -vvv
```

### Docker Installation Failures

```bash
# Check if system is Ubuntu/Debian
ansible -i inventory/hosts.ini rke_nodes -m setup -a "filter=ansible_os_family"

# Check OS release
ansible -i inventory/hosts.ini rke_nodes -m command -a "cat /etc/os-release"
```

### RKE Deployment Issues

```bash
# Check RKE logs in work directory (/tmp/rke-deploy/)
# Verify nodes have Docker running:
ansible -i inventory/hosts.ini rke_nodes -m command -a "docker --version" -b

# Check RKE cluster status
export KUBECONFIG=../merged-kubeconfig-rke
kubectl cluster-info
kubectl get nodes
```

### Longhorn/Nginx Installation Issues

```bash
# Verify kubeconfig is correct
kubectl cluster-info

# Check namespace creation
kubectl get namespace

# Watch pod deployment
kubectl get pods -n longhorn-system -w
kubectl get pods -n ingress-nginx -w

# Check Helm releases
helm list -A
```

## Tags

Run specific parts of playbooks with `--tags`:

```bash
# Install only Docker (skip RKE)
ansible-playbook -i inventory/hosts.ini rke.yml --tags "docker"

# Skip certain tasks
ansible-playbook -i inventory/hosts.ini rke.yml --skip-tags "verify"
```

## Examples

### Deploy full stack (Proxmox VMs + RKE + Longhorn)

```bash
# 1. Create VMs via Terraform
cd ../terraform/on-prem
terraform apply

# 2. Get VM IPs from Terraform output
# 3. Update ansible/inventory/hosts.ini with IPs

# 4. Deploy RKE cluster
cd ../../ansible
ansible-playbook -i inventory/hosts.ini rke.yml -v

# 5. Install Longhorn and Nginx
export KUBECONFIG=../merged-kubeconfig-rke
ansible-playbook -i inventory/hosts.ini longhorn-nginx.yml -v

# 6. Access Longhorn UI
kubectl get svc -n ingress-nginx
# Add LoadBalancer IP to /etc/hosts: <IP> longhorn.meiot.site
# Open browser: http://longhorn.meiot.site
```

### Deploy to existing cluster

```bash
# Just install Longhorn and Nginx on existing cluster
export KUBECONFIG=/path/to/existing/kubeconfig
ansible-playbook longhorn-nginx.yml -v
```

### Customize domain

```bash
ansible-playbook longhorn-nginx.yml \
  -e "longhorn_domain=storage.mycompany.com" \
  -v
```

## Advanced Options

### Skipping Docker Installation (if already installed)

```bash
ansible-playbook -i inventory/hosts.ini rke.yml --skip-tags "docker"
```

### Debugging with Verbose Output

```bash
# Show all variables sent to tasks
ansible-playbook -i inventory/hosts.ini rke.yml -vvvv

# Only dry-run (shows what would change)
ansible-playbook -i inventory/hosts.ini rke.yml --check
```

### Custom RKE Version

```bash
ansible-playbook -i inventory/hosts.ini rke.yml \
  -e "rke_version=v1.4.0" \
  -v
```

## Security Notes

- The playbooks use `StrictHostKeyChecking=no` for convenience in test environments. For production, remove this or use known_hosts.
- SSH keys are best managed via SSH agent or SSH config. Update inventory accordingly.
- kubeconfig files contain sensitive credentials—store securely and limit access.
- Use Ansible vault to encrypt sensitive variables (passwords, SSH keys).

## Related Documentation

- [RKE Documentation](https://rancher.com/docs/rke/latest/)
- [Longhorn Documentation](https://longhorn.io/docs/)
- [Nginx Ingress Documentation](https://kubernetes.github.io/ingress-nginx/)
- [Ansible Documentation](https://docs.ansible.com/)
