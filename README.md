# K3s GitOps Demo Cluster

A production-ready Kubernetes cluster on Hetzner Cloud, managed via GitOps with Flux CD. This repository demonstrates modern DevOps practices including Infrastructure as Code, GitOps workflows, and automated deployments.

## Architecture

- **Infrastructure**: Hetzner Cloud (1 master + 2 workers, CX22 instances)
- **Kubernetes**: K3s lightweight distribution
- **GitOps**: Flux CD for continuous delivery
- **Ingress**: Traefik with automatic TLS via cert-manager
- **DNS**: Hetzner DNS API integration
- **Domain**: k8s-demo.de with automatic subdomain management

## Repository Structure

```
.
├── terraform/              # Infrastructure as Code
│   └── environments/
│       └── demo/          # Demo environment config
├── ansible/               # Configuration management
│   ├── roles/
│   │   ├── common/       # Common setup tasks
│   │   ├── k3s-master/   # Master node configuration
│   │   └── k3s-worker/   # Worker node configuration
│   └── site.yml          # Main playbook
├── clusters/
│   └── demo/             # Flux cluster config
├── infrastructure/        # Core cluster services
│   ├── sources/          # Helm repositories
│   └── controllers/      # Ingress, cert-manager, etc.
└── apps/                 # Applications
    ├── wallabag/         # Read-it-later service
    └── linkding/         # Bookmark manager
```

## Prerequisites

### Local Development
- Terraform >= 1.0
- Ansible >= 2.9
- kubectl
- flux CLI (optional, for local testing)

### Required Secrets
Set these as GitHub repository secrets:
- `HETZNER_TOKEN` - Hetzner Cloud API token
- `SSH_PUBLIC_KEY` - Your SSH public key for server access
- `SSH_PRIVATE_KEY` - Your SSH private key for Ansible deployment
- `GITHUB_TOKEN` - Automatically provided by GitHub Actions

### Domain Setup
1. Register domain at Hetzner DNS (k8s-demo.de)
2. Create DNS zone in Hetzner DNS Console
3. Point nameservers to Hetzner DNS

## Getting Started

### 1. Fork and Clone
```bash
git clone https://github.com/YOUR_USERNAME/k3s-gitops.git
cd k3s-gitops
```

### 2. Add GitHub Secrets
Go to Settings > Secrets and Variables > Actions and add:
- `HETZNER_TOKEN`
- `SSH_PUBLIC_KEY`
- `SSH_PRIVATE_KEY`

### 3. Provision Infrastructure
Go to Actions > "Provision K3s Cluster" > Run workflow
- Choose "apply" to create infrastructure
- This will:
  - Create Hetzner Cloud servers
  - Configure networking and firewall
  - Install K3s via Ansible
  - Generate and upload kubeconfig

### 4. Bootstrap Flux
Go to Actions > "Bootstrap Flux" > Run workflow
- This will:
  - Install Flux CD on the cluster
  - Connect Flux to this GitHub repository
  - Deploy infrastructure components (Traefik, cert-manager)
  - Deploy applications (wallabag, linkding)

### 5. Configure DNS
After deployment, get the master node IP:
```bash
cd terraform/environments/demo
terraform output master_ip
```

Create A records in Hetzner DNS:
- `wallabag.k8s-demo.de` → `<master_ip>`
- `linkding.k8s-demo.de` → `<master_ip>`

## Deployed Applications

### Wallabag
A self-hosted read-it-later application
- URL: https://wallabag.k8s-demo.de
- Default credentials: Check application logs on first startup
- Storage: 5GB persistent volume

### Linkding
Minimalistic bookmark manager
- URL: https://linkding.k8s-demo.de
- First user to register becomes admin
- Storage: 1GB persistent volume

## Interview Demonstration Topics

### Infrastructure as Code (Terraform)
- **Location**: `terraform/environments/demo/`
- **Demonstrates**:
  - Multi-node cluster provisioning
  - Network configuration with private networking
  - Firewall rules and security setup
  - Variable management and outputs

### Configuration Management (Ansible)
- **Location**: `ansible/`
- **Demonstrates**:
  - Role-based playbook organization
  - Master/worker node differentiation
  - K3s installation and configuration
  - Automated kubeconfig extraction

### GitOps (Flux CD)
- **Location**: `clusters/demo/`, `infrastructure/`, `apps/`
- **Demonstrates**:
  - Declarative infrastructure management
  - Automatic reconciliation
  - Dependency management
  - Kustomization patterns

### Kubernetes Concepts
- **Namespaces**: Resource isolation per application
- **Deployments**: Application lifecycle management
- **Services**: Internal networking
- **Ingress**: External access with TLS
- **PersistentVolumeClaims**: Stateful storage
- **ConfigMaps/Secrets**: Configuration management

### Automated TLS/SSL
- **cert-manager**: Automatic certificate issuance
- **Let's Encrypt**: Production-grade certificates
- **DNS-01 Challenge**: Via Hetzner DNS API
- **Automatic renewal**: 30 days before expiry

### CI/CD (GitHub Actions)
- **Location**: `.github/workflows/`
- **Demonstrates**:
  - Infrastructure provisioning workflow
  - Ansible automation
  - Flux bootstrap process
  - Secret management

## Management Commands

### Local Access
```bash
# Download kubeconfig from GitHub Actions artifacts
# or from terraform output directory

export KUBECONFIG=./kubeconfig

# View all resources
kubectl get all -A

# Check Flux status
flux get all -A

# View application logs
kubectl logs -n wallabag -l app=wallabag
kubectl logs -n linkding -l app=linkding
```

### Flux Operations
```bash
# Force reconciliation
flux reconcile source git flux-system
flux reconcile kustomization apps

# Suspend/resume automated deployments
flux suspend kustomization apps
flux resume kustomization apps
```

### Updating Applications
Simply commit changes to this repository - Flux will automatically deploy them!

```bash
# Example: Scale wallabag
kubectl scale deployment wallabag -n wallabag --replicas=2
# OR edit apps/wallabag/deployment.yaml and commit
```

## Monitoring

### Check Cluster Health
```bash
kubectl get nodes
kubectl get pods -A
```

### Check Certificates
```bash
kubectl get certificate -A
kubectl describe certificate wallabag-tls -n wallabag
```

### Check Ingress
```bash
kubectl get ingress -A
```

## Teardown

### Destroy Infrastructure
Go to Actions > "Provision K3s Cluster" > Run workflow
- Choose "destroy" to remove all infrastructure
- This will delete all Hetzner Cloud resources

**Warning**: This will permanently delete all data!

## Cost Estimation

- 3x CX22 instances (2 vCPU, 4GB RAM): ~€18/month
- Network traffic: Usually within free tier
- DNS: Free with Hetzner
- **Total**: ~€18/month

## Troubleshooting

### Infrastructure Issues
```bash
cd terraform/environments/demo
terraform plan  # Check what would be created
terraform state list  # View current infrastructure
```

### Application Not Starting
```bash
kubectl describe pod -n <namespace> <pod-name>
kubectl logs -n <namespace> <pod-name>
```

### Certificate Issues
```bash
kubectl get certificate -A
kubectl describe certificate <cert-name> -n <namespace>
kubectl logs -n cert-manager -l app=cert-manager
```

### Flux Not Syncing
```bash
flux get all
flux logs
kubectl logs -n flux-system -l app=source-controller
```

## Learning Resources

- [K3s Documentation](https://docs.k3s.io/)
- [Flux CD Documentation](https://fluxcd.io/docs/)
- [Hetzner Cloud API](https://docs.hetzner.cloud/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [cert-manager Documentation](https://cert-manager.io/docs/)

## License

MIT

## Author

Created for interview demonstration purposes.
