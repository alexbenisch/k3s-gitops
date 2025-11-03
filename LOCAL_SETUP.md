# Local Setup Guide

This guide shows how to deploy the cluster using local tools (Terraform and Ansible) instead of GitHub Actions.

## Prerequisites

Install these tools on your local machine:

```bash
# Terraform
brew install terraform  # macOS
# or download from https://www.terraform.io/downloads

# Ansible
pip install ansible

# kubectl
brew install kubectl  # macOS
# or download from https://kubernetes.io/docs/tasks/tools/

# jq (for JSON processing)
brew install jq  # macOS
```

## Step 1: Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/k3s-gitops.git
cd k3s-gitops
```

## Step 2: Configure Environment Variables

```bash
# Set Terraform variables
export TF_VAR_hetzner_token="your-hetzner-api-token"
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"
```

**Note**: Your SSH public key will be added to all servers by Terraform.

## Step 3: Provision Infrastructure with Terraform

```bash
cd terraform/environments/demo

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply

# Save the outputs
terraform output
```

**Duration**: ~2-3 minutes

You should see outputs showing the master and worker IPs.

## Step 4: Generate Ansible Inventory

```bash
# From terraform/environments/demo directory
MASTER_IP=$(terraform output -raw master_ip)
WORKER_IPS=$(terraform output -json worker_ips | jq -r '.[]')

# Create inventory file
cat > ../../ansible/inventory/hosts <<EOF
[master]
k3s-master ansible_host=${MASTER_IP} ansible_user=root

[workers]
EOF

i=1
for ip in $WORKER_IPS; do
  echo "k3s-worker-${i} ansible_host=${ip} ansible_user=root" >> ../../ansible/inventory/hosts
  i=$((i+1))
done

cat >> ../../ansible/inventory/hosts <<EOF

[k3s_cluster:children]
master
workers
EOF

# View the generated inventory
cat ../../ansible/inventory/hosts
```

## Step 5: Run Ansible Playbook

Ansible will run from your local machine and connect to the servers via SSH using your private key (~/.ssh/id_rsa):

```bash
cd ../../ansible

# Test connectivity
ansible all -i inventory/hosts -m ping

# Run the playbook
ansible-playbook -i inventory/hosts site.yml
```

**What Ansible does**:
- Prepares all nodes (disables swap, enables IP forwarding, etc.)
- Installs K3s on the master node
- Joins worker nodes to the cluster
- Downloads kubeconfig to your local machine

**Duration**: ~5-8 minutes

## Step 6: Access the Cluster

```bash
# The kubeconfig is saved at the repository root
cd ..
export KUBECONFIG=$(pwd)/kubeconfig

# Verify cluster
kubectl get nodes
kubectl get pods -A
```

All 3 nodes should be in Ready state.

## Step 7: Bootstrap Flux (Local)

```bash
# Install Flux CLI
curl -s https://fluxcd.io/install.sh | sudo bash

# Bootstrap Flux
flux bootstrap github \
  --owner=YOUR_GITHUB_USERNAME \
  --repository=k3s-gitops \
  --branch=main \
  --path=clusters/demo \
  --personal

# Check Flux status
flux get all -A
```

**Duration**: ~3-5 minutes

Flux will automatically deploy:
- Traefik ingress controller
- cert-manager with Hetzner DNS webhook
- Wallabag application
- Linkding application

## Step 8: Configure DNS

Get your master IP:
```bash
cd terraform/environments/demo
terraform output master_ip
```

Add A records in Hetzner DNS Console:
- `wallabag.k8s-demo.de` → `<master_ip>`
- `linkding.k8s-demo.de` → `<master_ip>`

## Step 9: Verify Deployment

```bash
# Watch certificates being issued
kubectl get certificate -A -w

# Check applications
kubectl get pods -n wallabag
kubectl get pods -n linkding

# Check ingress
kubectl get ingress -A
```

Once certificates show `Ready: True`, visit:
- https://wallabag.k8s-demo.de
- https://linkding.k8s-demo.de

## Teardown

```bash
# Destroy infrastructure
cd terraform/environments/demo
terraform destroy
```

This will delete all Hetzner Cloud resources.

## Troubleshooting

### SSH Connection Issues
```bash
# Test SSH connection manually
ssh root@<server_ip>

# Check if public key is installed
ssh root@<server_ip> "cat ~/.ssh/authorized_keys"
```

### Ansible Issues
```bash
# Test with verbose output
ansible-playbook -i inventory/hosts site.yml -vvv

# Test specific host
ansible k3s-master -i inventory/hosts -m ping
```

### Cluster Issues
```bash
# SSH to master and check K3s
ssh root@<master_ip>
systemctl status k3s
k3s kubectl get nodes
journalctl -u k3s -f
```

## Advantages of Local Setup

- ✅ No GitHub secrets needed (except for Flux bootstrap)
- ✅ Faster iteration during development
- ✅ Direct control over execution
- ✅ Easier debugging with verbose output
- ✅ Use your existing SSH keys
- ✅ Can run Terraform plan before apply

## GitHub Actions vs Local

**Use GitHub Actions when**:
- Demonstrating CI/CD automation
- Want everything in Git history
- Prefer declarative workflows

**Use Local when**:
- Testing configurations
- Faster development iteration
- Don't want to commit secrets
- Need interactive debugging
