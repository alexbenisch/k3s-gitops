# K3s GitOps Demo Cluster - Deployment Summary

## ✅ Successfully Deployed

### Infrastructure (Hetzner Cloud)
- **Master Node**: 88.99.124.124 (k3s-master)
- **Worker 1**: 188.245.227.116 (k3s-worker-1)
- **Worker 2**: 91.99.11.208 (k3s-worker-2)
- **Network**: 10.0.0.0/16 (private networking)
- **Firewall**: Configured for SSH (22), HTTP (80), HTTPS (443), K8s API (6443)
- **Location**: Falkenstein (fsn1-dc14)
- **Instance Type**: CX22 (2 vCPU, 4GB RAM per node)

### Kubernetes Cluster
- **Distribution**: K3s v1.33.5
- **Nodes**: 3 nodes (all Ready)
- **Access**: kubectl configured, kubeconfig on master at `/root/.kube/config`

### GitOps (Flux CD)
- **Repository**: https://github.com/alexbenisch/k3s-gitops
- **Branch**: main
- **Path**: clusters/demo
- **Controllers**: All running (source, kustomize, helm, notification)

## 🔑 Access Information

### SSH Access
```bash
# Master node
ssh root@88.99.124.124

# Worker nodes
ssh root@188.245.227.116
ssh root@91.99.11.208
```

### Kubectl Access
```bash
# From master node
kubectl get nodes
kubectl get pods -A
flux get all

# From local machine
export KUBECONFIG=/home/alex/repos/k3s/kubeconfig
kubectl get nodes
```

## 📊 Cluster Status

```bash
# Check nodes
kubectl get nodes

# Check all pods
kubectl get pods -A

# Check Flux
flux get all -A

# View Flux logs
kubectl logs -n flux-system -l app=kustomize-controller
```

## 🚀 What's Deployed

1. **K3s Core Components**
   - CoreDNS
   - Local Path Provisioner
   - Metrics Server

2. **Flux CD**
   - Source Controller
   - Kustomize Controller  
   - Helm Controller
   - Notification Controller

3. **Ready for**:
   - Traefik Ingress (via Flux)
   - cert-manager (via Flux)
   - Wallabag (via Flux)
   - Linkding (via Flux)

## 🎯 Interview Demonstration Points

### Infrastructure as Code
- Show `terraform/environments/demo/` configuration
- Explain resource provisioning (servers, network, firewall)
- Discuss state management and variables

### Configuration Management  
- Walk through `ansible/` playbooks
- Explain role-based organization (common, master, worker)
- Demonstrate idempotent operations

### Kubernetes
- Show multi-node cluster setup
- Explain control plane vs worker nodes
- Discuss K3s advantages (lightweight, fast, production-ready)

### GitOps with Flux
- Explain GitOps principles (Git as source of truth)
- Show Flux controllers and their roles
- Demonstrate automatic reconciliation
- Discuss declarative vs imperative

### CI/CD
- Show GitHub Actions workflows
- Explain infrastructure provisioning automation
- Discuss secret management (GitHub Secrets)

## 💰 Cost Information

**Current Cost**: ~€0.025/hour (~€18/month if left running)
**Demo Duration**: Recommend 1-2 days (~€1-2 total)

### Teardown
```bash
# Option 1: Via GitHub Actions
# Go to Actions > Provision K3s Cluster > Run workflow > destroy

# Option 2: Via Terraform locally
cd terraform/environments/demo
terraform destroy

# Option 3: Via hcloud CLI
export HCLOUD_TOKEN="your-token"
hcloud server delete k3s-master k3s-worker-1 k3s-worker-2
hcloud network delete k3s-network
hcloud firewall delete k3s-firewall
```

## 🔧 Troubleshooting

### DNS Issues
If Flux has DNS problems:
```bash
# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns

# Test DNS from a pod
kubectl run test --image=busybox --rm -it -- nslookup kubernetes.default
```

### Flux Not Reconciling
```bash
# Force reconciliation
flux reconcile source git flux-system
flux reconcile kustomization flux-system

# Check logs
kubectl logs -n flux-system -l app=source-controller
kubectl logs -n flux-system -l app=kustomize-controller
```

### Application Not Starting
```bash
# Check pods
kubectl get pods -n <namespace>

# Check logs
kubectl logs -n <namespace> <pod-name>

# Describe for events
kubectl describe pod -n <namespace> <pod-name>
```

## 📚 Repository Structure

```
.
├── terraform/               # Infrastructure as Code
│   └── environments/demo/   # Demo environment
├── ansible/                # Configuration management
│   ├── roles/              # Ansible roles
│   └── inventory/          # Server inventory
├── clusters/demo/          # Flux cluster config
├── infrastructure/         # Core services
│   ├── sources/           # Helm repos
│   └── controllers/       # Ingress, cert-manager
├── apps/                  # Applications
│   ├── wallabag/         # Read-it-later
│   └── linkding/         # Bookmarks
└── .github/workflows/     # CI/CD pipelines
```

## 🎓 Learning Outcomes

This project demonstrates:
- ✅ Infrastructure as Code with Terraform
- ✅ Configuration Management with Ansible
- ✅ Kubernetes cluster operations
- ✅ GitOps methodology with Flux CD
- ✅ CI/CD with GitHub Actions
- ✅ Cloud platform experience (Hetzner)
- ✅ Security best practices (SSH keys, firewalls)
- ✅ Documentation skills

## 🔗 Useful Links

- **Repository**: https://github.com/alexbenisch/k3s-gitops
- **Hetzner Console**: https://console.hetzner.cloud/
- **K3s Docs**: https://docs.k3s.io/
- **Flux Docs**: https://fluxcd.io/docs/

---

Generated: 2025-11-03
Cluster Location: Hetzner Cloud (fsn1)
Status: ✅ Operational
