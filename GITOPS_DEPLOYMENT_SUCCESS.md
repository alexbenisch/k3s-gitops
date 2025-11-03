# GitOps Deployment - Success Summary

**Date**: 2025-11-03
**Status**: ✅ Fully Operational

## Overview

Successfully deployed a production-ready Kubernetes cluster with fully automated GitOps deployment using Flux CD. Both applications are accessible via HTTPS with valid Let's Encrypt certificates.

## Deployed Applications

### Wallabag (Read-it-later Service)
- **URL**: https://wallabag.k8s-demo.de
- **Certificate**: Let's Encrypt (Issuer: R12)
- **Status**: ✅ Running
- **TLS**: Valid, auto-renewing

### Linkding (Bookmark Manager)
- **URL**: https://linkding.k8s-demo.de
- **Certificate**: Let's Encrypt (Issuer: R13)
- **Status**: ✅ Running
- **TLS**: Valid, auto-renewing

## Infrastructure

### Cluster Configuration
- **Provider**: Hetzner Cloud
- **Location**: Falkenstein (fsn1-dc14)
- **Nodes**:
  - 1x Master (k3s-master): 88.99.124.124
  - 2x Workers (k3s-worker-1, k3s-worker-2)
- **Instance Type**: CX22 (2 vCPU, 4GB RAM each)
- **Network**: Private network 10.0.0.0/16
- **Kubernetes**: K3s v1.33.5

### DNS Configuration
- **Domain**: k8s-demo.de
- **Provider**: Hetzner DNS
- **Records**:
  - wallabag.k8s-demo.de → 88.99.124.124
  - linkding.k8s-demo.de → 88.99.124.124

## GitOps Setup

### Flux CD Configuration
- **Version**: v2.7.3
- **Repository**: github.com/alexbenisch/k3s-gitops
- **Branch**: main
- **Sync Path**: ./clusters/demo
- **Sync Interval**: 1 minute (source), 10 minutes (reconciliation)
- **Status**: ✅ All Kustomizations healthy

### Deployment Structure
```
clusters/demo/
├── flux-system/              # Flux CD controllers
├── infrastructure.yaml       # Infrastructure layer
├── infrastructure-configs.yaml # Infrastructure configurations
└── apps.yaml                 # Application layer

infrastructure/
├── sources/
│   └── bitnami.yaml         # Helm repository
├── controllers/
│   ├── traefik.yaml         # Ingress controller
│   ├── cert-manager.yaml    # Certificate management
│   └── cert-manager-webhook-hetzner.yaml
└── configs/
    ├── cert-manager-clusterissuers.yaml
    └── hetzner-dns-rbac.yaml

apps/
├── wallabag/                # Wallabag manifests
├── linkding/                # Linkding manifests
└── kustomization.yaml
```

### Dependency Order
1. **flux-system** → Core Flux controllers
2. **infrastructure** → Traefik, cert-manager, webhooks
3. **infrastructure-configs** → ClusterIssuers, RBAC
4. **apps** → Applications (depends on infrastructure)

## Key Components

### Traefik Ingress Controller
- **Version**: v2.11.0 (Helm chart v26.x)
- **Configuration**:
  - Deployed on master node via nodeSelector
  - hostPort binding (80 → 80, 443 → 443)
  - Single replica for consistency
- **Service Type**: LoadBalancer (with hostPort fallback)
- **Status**: ✅ Running on k3s-master

### cert-manager
- **Version**: v1.13.6
- **Challenge Type**: DNS-01 via Hetzner DNS webhook
- **Issuers**:
  - letsencrypt-staging (for testing)
  - letsencrypt-prod (active)
- **Webhook**: cert-manager-webhook-hetzner v1.4.0
- **Status**: ✅ Certificates issued and valid

### Certificate Management
- **Automatic Issuance**: Via DNS-01 ACME challenges
- **Renewal**: Automatic, 30 days before expiry
- **Verification**: SSL certificates verified by Let's Encrypt
- **Status**: ✅ Both certificates valid

## Security Configuration

### Secrets Management
**Important**: Secrets are NOT stored in Git for security reasons.

The following secrets are created directly on the cluster:
- `hetzner-dns-token` (cert-manager namespace): Hetzner DNS API token
- `flux-system` (flux-system namespace): GitHub deploy key

**Storage Locations**:
- Local: `~/.zprofile` - Contains `HETZNER_DNS_TOKEN` and `HETZNER_TOKEN`
- GitHub: Repository secrets - `HETZNER_TOKEN`, `HETZNER_DNS_TOKEN`
- Master Node: `/root/flux-deploy-key` - SSH deploy key for Flux

### RBAC Configuration
- ServiceAccount: `cert-manager-webhook-hetzner`
- Role: Secret reader for `hetzner-dns-token`
- Scoped to: cert-manager namespace only

### GitHub Deploy Key
- **Type**: ED25519
- **Purpose**: Flux GitOps synchronization
- **Permissions**: Write access (for automated commits if needed)
- **Location**: Configured in GitHub repo settings

## Deployment Timeline & Issues Resolved

### Initial Issues Encountered
1. ❌ **Flux Sync Failures**: HelmRelease API version mismatch
   - **Cause**: Using deprecated `helm.toolkit.fluxcd.io/v2beta1`
   - **Fix**: Updated to `v2`

2. ❌ **Traefik Not Accessible**: Ports 80/443 not responding
   - **Cause**: LoadBalancer service with no cloud provider
   - **Fix**: Added hostPort configuration (80, 443)

3. ❌ **Traefik on Wrong Node**: Running on worker instead of master
   - **Cause**: No node affinity configured
   - **Fix**: Added nodeSelector and tolerations for control-plane

4. ❌ **Certificate Challenges Failing**: DNS-01 challenges stuck pending
   - **Cause**: RBAC permissions missing for webhook
   - **Fix**: Created Role and RoleBinding for secret access

5. ❌ **Wrong Secret Key Name**: Webhook expecting `api-key` not `api-token`
   - **Fix**: Recreated secret with correct key name

### Final Status
✅ All issues resolved
✅ Full GitOps workflow operational
✅ Automated deployments working
✅ Let's Encrypt certificates valid

## Testing & Verification

### Certificate Verification
```bash
# Wallabag certificate
curl -vI https://wallabag.k8s-demo.de 2>&1 | grep -E "(subject:|issuer:)"
# Output:
#   subject: CN=wallabag.k8s-demo.de
#   issuer: C=US; O=Let's Encrypt; CN=R12

# Linkding certificate
curl -vI https://linkding.k8s-demo.de 2>&1 | grep -E "(subject:|issuer:)"
# Output:
#   subject: CN=linkding.k8s-demo.de
#   issuer: C=US; O=Let's Encrypt; CN=R13
```

### Flux Status Check
```bash
ssh root@88.99.124.124 "kubectl get kustomization -n flux-system"
# All should show READY=True
```

### Application Health
```bash
ssh root@88.99.124.124 "kubectl get pods -n wallabag -n linkding"
# All pods should be Running
```

## How to Use GitOps Workflow

### Making Changes
1. **Edit manifests** in this repository (apps/ or infrastructure/)
2. **Commit and push** to main branch
3. **Wait 1-10 minutes** for Flux to automatically deploy
4. **Verify** deployment succeeded

### Force Immediate Sync
```bash
# From master node (if flux CLI installed)
flux reconcile source git flux-system
flux reconcile kustomization apps

# Or wait for automatic sync (max 10 minutes)
```

### Adding New Applications
1. Create directory in `apps/`
2. Add Kubernetes manifests (Deployment, Service, Ingress, etc.)
3. Update `apps/kustomization.yaml` to include new directory
4. Commit and push - Flux handles the rest!

### Updating Existing Applications
1. Edit the manifest files in `apps/`
2. Commit and push
3. Flux automatically applies changes

## Monitoring & Management

### Check Cluster Status
```bash
# SSH to master
ssh root@88.99.124.124

# View all pods
kubectl get pods -A

# Check Flux health
kubectl get kustomization -n flux-system

# View certificates
kubectl get certificate -A

# Check Traefik
kubectl get pods -n traefik
kubectl get svc -n traefik
```

### View Application Logs
```bash
# Wallabag
kubectl logs -n wallabag -l app=wallabag --tail=50

# Linkding
kubectl logs -n linkding -l app=linkding --tail=50
```

### Certificate Details
```bash
kubectl describe certificate wallabag-tls -n wallabag
kubectl describe certificate linkding-tls -n linkding
```

## Cost Information

**Monthly Cost**: ~€18/month (3x CX22 instances)
**Recommendation**: Suitable for demo/development environments

## Next Steps & Recommendations

### Completed ✅
- [x] Infrastructure provisioned via Terraform
- [x] Cluster configured via Ansible
- [x] Flux CD bootstrapped and syncing
- [x] Traefik ingress controller deployed
- [x] cert-manager with Let's Encrypt integration
- [x] DNS records configured
- [x] Applications deployed with TLS
- [x] GitOps workflow fully operational

### Optional Enhancements
- [ ] Add monitoring stack (Prometheus + Grafana)
- [ ] Implement backup solution for persistent volumes
- [ ] Add more applications via GitOps
- [ ] Set up external-dns for automatic DNS management
- [ ] Configure Flux notifications (Slack, Discord, etc.)
- [ ] Add Sealed Secrets or External Secrets Operator for secret management
- [ ] Implement network policies for security
- [ ] Add resource limits and quotas

## Troubleshooting

### Flux Not Syncing
```bash
# Check Flux logs
kubectl logs -n flux-system -l app=source-controller
kubectl logs -n flux-system -l app=kustomize-controller

# Check GitRepository status
kubectl describe gitrepository flux-system -n flux-system
```

### Certificate Not Issuing
```bash
# Check certificate status
kubectl describe certificate <cert-name> -n <namespace>

# Check challenges
kubectl get challenges -A

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager
```

### Application Not Starting
```bash
# Describe pod for events
kubectl describe pod <pod-name> -n <namespace>

# View logs
kubectl logs <pod-name> -n <namespace>
```

## Documentation References

- [Flux CD Documentation](https://fluxcd.io/docs/)
- [K3s Documentation](https://docs.k3s.io/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [Hetzner Cloud API](https://docs.hetzner.cloud/)
- [Hetzner DNS API](https://dns.hetzner.com/api-docs/)

## Interview Talking Points

This project demonstrates:

1. **Infrastructure as Code**: Terraform for cloud resource provisioning
2. **Configuration Management**: Ansible for cluster setup
3. **GitOps Methodology**: Flux CD for declarative deployments
4. **Kubernetes Operations**: Multi-node cluster management
5. **Security Best Practices**: TLS certificates, RBAC, secret management
6. **Cloud Platforms**: Hetzner Cloud experience
7. **Networking**: DNS configuration, ingress controllers
8. **Troubleshooting**: Systematic issue resolution and debugging
9. **Documentation**: Comprehensive project documentation
10. **Automation**: Fully automated deployment pipeline

---

**Status**: Production Ready ✅
**Last Updated**: 2025-11-03
**Maintained By**: GitOps via Flux CD
