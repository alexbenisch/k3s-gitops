# Interview Demonstration Guide

## Quick Pitch (30 seconds)

"I've built a production-ready Kubernetes cluster on Hetzner Cloud using modern DevOps practices. The entire infrastructure is defined as code using Terraform, configured with Ansible, and applications are deployed via GitOps with Flux CD. Everything is automated through GitHub Actions, including automated TLS certificate management via Let's Encrypt and Hetzner DNS API."

## Technical Stack Overview

### Infrastructure Layer
- **Cloud Provider**: Hetzner Cloud (cost-effective European provider)
- **IaC Tool**: Terraform
- **Cluster**: K3s (lightweight Kubernetes, perfect for demos)
- **Configuration**: Ansible

### Kubernetes Layer
- **GitOps**: Flux CD
- **Ingress**: Traefik
- **TLS**: cert-manager with Let's Encrypt
- **DNS**: Hetzner DNS API integration

### Application Layer
- **Wallabag**: Read-it-later service (demonstrates stateful apps)
- **Linkding**: Bookmark manager (demonstrates persistent storage)

### CI/CD Layer
- **GitHub Actions**: Infrastructure provisioning and Flux bootstrap
- **GitHub Secrets**: Secure credential management

## Demo Script (15 minutes)

### 1. Repository Walkthrough (3 min)

```bash
# Show clean repository structure
tree -L 2 .

# Explain key directories:
# - terraform/: Infrastructure definition
# - ansible/: Server configuration
# - infrastructure/: Core K8s services
# - apps/: Applications
# - clusters/: Flux configuration
```

**Key Points**:
- Separation of concerns (infra vs apps)
- Everything version-controlled
- Declarative configuration

### 2. Infrastructure as Code (3 min)

```bash
cd terraform/environments/demo

# Show main.tf
cat main.tf
```

**Highlight**:
- Multi-node cluster (1 master, 2 workers)
- Private networking (10.0.0.0/16)
- Firewall configuration
- Variable usage for flexibility

```bash
# Show how secrets are handled
cat variables.tf
```

**Explain**:
- Variables with `sensitive = true`
- Using `TF_VAR_` environment variables
- No secrets in git (show .gitignore)

### 3. Configuration Management (2 min)

```bash
cd ../../ansible

# Show playbook structure
cat site.yml

# Show role organization
ls roles/
```

**Key Points**:
- Role-based organization (common, master, worker)
- Idempotent operations
- Automatic kubeconfig extraction

### 4. GitOps with Flux (3 min)

```bash
cd ../clusters/demo

# Show Flux configuration
cat infrastructure.yaml
cat apps.yaml
```

**Explain**:
- Flux watches this Git repo
- Automatically deploys changes
- Dependency management (infrastructure before apps)

```bash
# Show live cluster status
export KUBECONFIG=~/.kube/k3s-demo-config
flux get all -A
```

### 5. Application Deployment (2 min)

```bash
cd ../../apps/wallabag

# Show Kubernetes manifests
cat deployment.yaml
cat ingress.yaml
```

**Highlight**:
- Standard Kubernetes resources
- Persistent storage (PVCs)
- Ingress with TLS annotations
- cert-manager automatic certificate issuance

```bash
# Show running applications
kubectl get pods -n wallabag -n linkding
kubectl get certificate -A
kubectl get ingress -A
```

### 6. Live Demo (2 min)

- Open browser to https://wallabag.k8s-demo.de
- Show valid TLS certificate
- Open https://linkding.k8s-demo.de
- Explain how DNS + cert-manager work together

**Bonus**: Show a live update
```bash
# Edit replica count
vim apps/wallabag/deployment.yaml
# Change replicas: 1 to replicas: 2

git add apps/wallabag/deployment.yaml
git commit -m "Scale wallabag to 2 replicas"
git push

# Watch Flux deploy automatically
watch kubectl get pods -n wallabag
```

## Common Interview Questions & Answers

### Q: Why K3s instead of full Kubernetes?
**A**: K3s is perfect for demos and edge deployments. It's:
- Lightweight (~70MB binary)
- Easy to install and manage
- Fully compatible with K8s APIs
- Production-ready (used by many companies)
- Cost-effective for learning/demos

### Q: Why Flux over ArgoCD?
**A**: Both are excellent. I chose Flux because:
- Native Kubernetes resources (CRDs)
- Pull-based model (more secure)
- Better for multi-cluster setups
- Integrated with Kustomize/Helm
- Cloud Native Computing Foundation project

Could easily demonstrate ArgoCD instead - it's more UI-focused.

### Q: How do you handle secrets?
**A**: Multi-layered approach:
- **GitHub Secrets**: For CI/CD credentials (Hetzner token, SSH keys)
- **Environment Variables**: TF_VAR_ prefix for Terraform
- **Kubernetes Secrets**: For application credentials
- **Future**: Would add Sealed Secrets or SOPS for GitOps secrets
- **Future**: External Secrets Operator for cloud secret managers

### Q: What about monitoring and logging?
**A**: This demo focuses on core infrastructure. In production I'd add:
- Prometheus + Grafana for metrics
- Loki + Promtail for logs
- AlertManager for alerting
- Uptime monitoring (e.g., UptimeRobot)

All deployable via Flux in the `infrastructure/` directory.

### Q: How do you handle backups?
**A**: Currently not implemented (keeping demo simple). Would add:
- Velero for Kubernetes resource backups
- Application-level backups (database dumps)
- S3-compatible storage (MinIO or Hetzner Object Storage)
- Automated backup schedule
- Disaster recovery procedures

### Q: What about security?
**A**: Current security measures:
- SSH key-only authentication (no passwords)
- Firewall rules (only necessary ports open)
- Private networking for inter-node communication
- Automated TLS certificates
- No secrets in Git
- Regular security updates (would add unattended-upgrades)

**Production additions**:
- Network policies
- Pod Security Standards
- RBAC for fine-grained access
- Audit logging
- Vulnerability scanning
- Intrusion detection

### Q: How do you test infrastructure changes?
**A**: Current approach:
- Terraform plan before apply
- Ansible check mode (--check flag)
- Separate environments (demo, staging, prod)

**Would add**:
- Terratest for infrastructure testing
- Molecule for Ansible testing
- Kubernetes policy testing (OPA/Gatekeeper)
- Smoke tests after deployment

### Q: What's the cost?
**A**: Very budget-friendly:
- 3x CX22 instances: ~€18/month (~€0.025/hour)
- Can destroy when not needed
- DNS and traffic included
- Total demo cost: < €1 if run for a day

### Q: How would you scale this?
**A**: Multiple approaches:
- **Horizontal**: Add more worker nodes (Terraform + Ansible)
- **Vertical**: Upgrade instance types (Terraform variables)
- **Application**: HorizontalPodAutoscaler for apps
- **Geographic**: Multi-region clusters with Flux
- **Advanced**: Service mesh (Linkerd/Istio) for traffic management

### Q: What did you learn building this?
**A**:
- Deep dive into GitOps principles
- Hands-on with Flux CD (previously only used ArgoCD)
- Hetzner Cloud API and DNS integration
- cert-manager webhook system
- K3s architecture and differences from full K8s
- GitHub Actions for infrastructure automation
- Importance of good documentation

**Challenges overcome**:
- cert-manager DNS-01 challenge configuration
- Ansible inventory generation from Terraform
- GitHub Actions artifact passing between jobs
- Traefik configuration for proper TLS

## Advanced Discussion Topics

### CI/CD Pipeline Evolution
- Current: Manual workflow dispatch
- Next: Automatic on push (with approvals)
- Advanced: Preview environments per PR

### Multi-Environment Strategy
```
environments/
  ├── dev/
  ├── staging/
  └── production/
```
Each with own Terraform state and Flux path.

### Application Deployment Strategies
- Blue/Green deployments
- Canary releases with Flagger
- Progressive delivery

### Observability Stack
```
infrastructure/observability/
  ├── prometheus/
  ├── grafana/
  ├── loki/
  └── tempo/
```

### Disaster Recovery
- Velero automated backups
- DR runbooks
- RTO/RPO definitions
- Regular DR drills

## Repository Highlights for Resume/Portfolio

**GitHub README.md**: Comprehensive documentation with:
- Architecture diagrams
- Setup instructions
- Cost breakdown
- Troubleshooting guide

**SETUP.md**: Step-by-step guide that anyone can follow

**Clean Git History**: Meaningful commits, proper structure

**Best Practices**:
- No secrets in repo
- Clear separation of concerns
- Comprehensive .gitignore
- Example files for sensitive data

## Follow-up Materials

After the interview, share:
- GitHub repository link
- Live demo URLs (if kept running)
- Architecture diagram (if created)
- Blog post about the project (if written)

## Quick Commands Reference

```bash
# Infrastructure
cd terraform/environments/demo && terraform plan
cd ansible && ansible-playbook -i inventory/hosts site.yml

# Cluster access
export KUBECONFIG=~/.kube/k3s-demo-config
kubectl get all -A

# Flux operations
flux get all -A
flux reconcile source git flux-system
flux reconcile kustomization apps

# Application logs
kubectl logs -n wallabag -l app=wallabag
kubectl logs -n linkding -l app=linkding

# Certificate debugging
kubectl get certificate -A
kubectl describe certificate wallabag-tls -n wallabag
kubectl logs -n cert-manager -l app=cert-manager

# Teardown
cd terraform/environments/demo && terraform destroy
```

## Confidence Boosters

Before the interview, verify:
- [ ] All nodes are healthy: `kubectl get nodes`
- [ ] All Flux resources synced: `flux get all -A`
- [ ] Applications accessible via HTTPS
- [ ] Certificates valid and not expiring soon
- [ ] Git history is clean
- [ ] README is up-to-date

Remember: **You built this from scratch. You understand every component. You can explain any design decision.**

Good luck! 🚀
