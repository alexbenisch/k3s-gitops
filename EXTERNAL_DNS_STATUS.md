# External-DNS Setup Status

## Date: 2025-11-03

## ✅ Successfully Completed

### 1. Flux Sync Issue - FIXED
- Updated all HelmRelease manifests from `helm.toolkit.fluxcd.io/v2beta1` to `v2`
- Reorganized ClusterIssuers into separate configs directory
- Created infrastructure-configs Kustomization that depends on infrastructure
- All Flux Kustomizations are now healthy and syncing

### 2. Infrastructure Deployed
- **cert-manager**: v1.13.6 - Running ✓
- **cert-manager-webhook-hetzner**: v1.4.0 - Running ✓
- **Traefik**: v2.11.0 - Running ✓
- **ClusterIssuers**: letsencrypt-prod and letsencrypt-staging created ✓

### 3. Applications Deployed
- **Linkding**: Running with Ingress configured
- **Wallabag**: Running with Ingress configured

## ❌ Current Issue: External-DNS

### Problem Description
Attempting to set up automated DNS management via external-dns with Hetzner DNS provider.

### Architecture
```
external-dns pod → webhook service → webhook pod → Hetzner DNS API
```

### Current Status
- **Webhook Pod**: Running (1/1) - Health checks passing
- **Webhook Service**: Created with endpoints
- **external-dns Pod**: CrashLoopBackOff - Cannot connect to webhook

### Root Cause
The Hetzner webhook container (`btribit/external-dns-hetzner-webhook:latest`) is listening on `localhost:8888` instead of `0.0.0.0:8888`.

**Evidence**:
```bash
# From webhook logs:
time="2025-11-03T16:29:40Z" level=info msg="Starting webhook server on localhost:8888"

# Connection test from another pod fails:
curl: (7) Failed to connect to external-dns-hetzner-webhook.external-dns.svc.cluster.local port 8888
```

**Environment Variables Set** (but ignored by container):
- `SERVER_HOST`: 0.0.0.0
- `SERVER_PORT`: 8888
- `HETZNER_API_KEY`: (from secret)
- `DOMAIN_FILTER`: k8s-demo.de

### Files Modified
- `infrastructure/controllers/external-dns.yaml` - Contains:
  - Webhook Deployment with health probes fixed
  - external-dns Deployment with RBAC
  - Service and Secret configurations

## Possible Next Steps

### Option 1: Different Webhook Image
Find or build a webhook image that properly binds to 0.0.0.0

### Option 2: Direct Hetzner API Integration
Create a simple controller that:
- Watches Kubernetes Ingress resources
- Directly calls Hetzner DNS API (https://dns.hetzner.com/api-docs/)
- Much simpler than webhook pattern

### Option 3: Sidecar Pattern
Deploy external-dns and webhook in same pod to avoid network issues

### Option 4: Manual DNS Setup
Configure DNS records manually in Hetzner and skip automated DNS management

## Testing Commands

```bash
# Check pod status
kubectl get pods -n external-dns

# Check webhook logs
kubectl logs -n external-dns -l app=external-dns-hetzner-webhook

# Check external-dns logs
kubectl logs -n external-dns -l app=external-dns

# Test webhook connectivity
kubectl run test-curl --image=curlimages/curl:latest --rm -it --restart=Never -- \
  curl -v http://external-dns-hetzner-webhook.external-dns.svc.cluster.local:8888/

# Check service endpoints
kubectl get endpoints -n external-dns external-dns-hetzner-webhook
```

## Notes
- The simpler approach mentioned by user (direct Hetzner API) would have avoided webhook complexity
- Hetzner DNS API is straightforward REST API
- Could implement as simple CronJob or lightweight controller
