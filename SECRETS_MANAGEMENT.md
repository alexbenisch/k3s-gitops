# Secrets Management Guide

## Overview

This document explains how secrets are managed in this GitOps repository. For security reasons, **secrets are NOT stored in Git**.

## Secret Types

### 1. GitHub Repository Secrets

These are stored in GitHub Settings → Secrets and variables → Actions:

| Secret Name | Purpose | Used By |
|-------------|---------|---------|
| `HETZNER_TOKEN` | Hetzner Cloud API token | Terraform, GitHub Actions |
| `HETZNER_DNS_TOKEN` | Hetzner DNS API token | cert-manager (via manual K8s secret) |
| `SSH_PUBLIC_KEY` | SSH public key for server access | Terraform |
| `SSH_PRIVATE_KEY` | SSH private key for Ansible | GitHub Actions |
| `GITHUB_TOKEN` | GitHub API token | Automatically provided by GitHub |

**To add/update**:
```bash
gh secret set SECRET_NAME -b "secret-value" -R alexbenisch/k3s-gitops
```

### 2. Kubernetes Secrets (On-Cluster)

These must be created manually on the cluster and are NOT stored in Git:

#### Hetzner DNS Token (cert-manager)

**Purpose**: Enables cert-manager to perform DNS-01 ACME challenges for Let's Encrypt certificates.

**Create**:
```bash
kubectl create secret generic hetzner-dns-token \
  --from-literal=api-key=YOUR_HETZNER_DNS_API_TOKEN \
  --namespace=cert-manager
```

**Used by**:
- cert-manager-webhook-hetzner
- ClusterIssuers (letsencrypt-prod, letsencrypt-staging)

**RBAC**: ServiceAccount `cert-manager-webhook-hetzner` has read-only access via Role and RoleBinding in `infrastructure/configs/hetzner-dns-rbac.yaml`

#### Flux System Secret (GitOps)

**Purpose**: SSH deploy key for Flux to sync with GitHub repository.

**Create**:
```bash
kubectl create secret generic flux-system \
  --from-file=identity=/path/to/flux-deploy-key \
  --from-file=identity.pub=/path/to/flux-deploy-key.pub \
  --from-literal=known_hosts="github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl" \
  --namespace=flux-system
```

**Used by**: Flux source-controller for GitRepository sync

**Note**: This secret is typically created automatically during Flux bootstrap.

### 3. Local Environment Variables

These are stored in your local `~/.zprofile` or `~/.bashrc`:

```bash
export HETZNER_TOKEN="your-hetzner-cloud-token"
export HETZNER_DNS_TOKEN="your-hetzner-dns-token"
export GITHUB_TOKEN="your-github-token"
```

**Purpose**: Used for local Terraform and kubectl operations.

## Security Best Practices

### ✅ DO

1. **Use separate tokens** for Cloud API and DNS API
2. **Create secrets manually** on the cluster via kubectl
3. **Use RBAC** to limit secret access to only what's needed
4. **Rotate tokens regularly** (at least every 90 days)
5. **Store tokens in password manager** for team access
6. **Use GitHub's secret scanner** to detect accidental commits
7. **Review `.gitignore`** to ensure secret files are excluded

### ❌ DON'T

1. **Never commit secrets** to Git (even encrypted)
2. **Don't use the same token** for multiple purposes
3. **Don't share tokens** via insecure channels (Slack, email)
4. **Don't hardcode secrets** in manifests
5. **Don't store secrets** in container images
6. **Don't use default/demo secrets** in production

## Secret Rotation

### Hetzner DNS Token

1. Create new token in Hetzner DNS Console
2. Update GitHub secret:
   ```bash
   gh secret set HETZNER_DNS_TOKEN -b "new-token"
   ```
3. Update Kubernetes secret:
   ```bash
   kubectl delete secret hetzner-dns-token -n cert-manager
   kubectl create secret generic hetzner-dns-token \
     --from-literal=api-key=NEW_TOKEN \
     --namespace=cert-manager
   ```
4. Delete old token from Hetzner Console
5. Update local environment variable in `~/.zprofile`

### Flux Deploy Key

1. Generate new SSH key:
   ```bash
   ssh-keygen -t ed25519 -f ./new-flux-deploy-key -N ""
   ```
2. Add new key to GitHub repo deploy keys
3. Update Kubernetes secret:
   ```bash
   kubectl create secret generic flux-system \
     --from-file=identity=/path/to/new-flux-deploy-key \
     --from-file=identity.pub=/path/to/new-flux-deploy-key.pub \
     --from-literal=known_hosts="..." \
     --namespace=flux-system \
     --dry-run=client -o yaml | kubectl apply -f -
   ```
4. Restart Flux controllers:
   ```bash
   kubectl rollout restart deployment -n flux-system
   ```
5. Remove old deploy key from GitHub

## Alternative Solutions (Future Enhancements)

For enhanced secret management, consider:

### 1. Sealed Secrets
- Encrypts secrets so they can be stored in Git
- Only the cluster can decrypt them
- https://github.com/bitnami-labs/sealed-secrets

### 2. External Secrets Operator
- Syncs secrets from external secret managers
- Supports: AWS Secrets Manager, HashiCorp Vault, Azure Key Vault, etc.
- https://external-secrets.io/

### 3. SOPS (Secrets OPerationS)
- Encrypts YAML/JSON files with age or PGP
- Integrates with Flux for GitOps workflows
- https://github.com/getsops/sops

### 4. HashiCorp Vault
- Full-featured secret management platform
- Dynamic secrets, encryption as a service
- https://www.vaultproject.io/

## Troubleshooting

### Secret Not Found Errors

**Symptom**: Pods failing with "secret not found" errors

**Solution**:
```bash
# Check if secret exists
kubectl get secret SECRET_NAME -n NAMESPACE

# If missing, create it
kubectl create secret generic SECRET_NAME \
  --from-literal=key=value \
  --namespace=NAMESPACE
```

### Permission Denied Errors

**Symptom**: "secrets is forbidden: User cannot get resource"

**Solution**:
```bash
# Check RBAC
kubectl describe role ROLE_NAME -n NAMESPACE
kubectl describe rolebinding BINDING_NAME -n NAMESPACE

# Verify ServiceAccount has access
kubectl auth can-i get secrets --as=system:serviceaccount:NAMESPACE:SA_NAME -n NAMESPACE
```

### Certificate Challenges Failing

**Symptom**: DNS-01 challenges stuck pending, "unable to get secret" errors

**Solution**:
1. Verify secret exists with correct key name:
   ```bash
   kubectl get secret hetzner-dns-token -n cert-manager -o yaml
   # Should have key "api-key" (not "api-token")
   ```

2. Check RBAC permissions:
   ```bash
   kubectl get role,rolebinding -n cert-manager | grep hetzner
   ```

3. Recreate secret if needed:
   ```bash
   kubectl delete secret hetzner-dns-token -n cert-manager
   kubectl create secret generic hetzner-dns-token \
     --from-literal=api-key=TOKEN \
     --namespace=cert-manager
   ```

4. Delete certificates to retry:
   ```bash
   kubectl delete certificate CERT_NAME -n NAMESPACE
   # Certificate will be automatically recreated
   ```

## Accessing Secrets

### View Secret (Base64 Encoded)

```bash
kubectl get secret SECRET_NAME -n NAMESPACE -o yaml
```

### Decode Secret Value

```bash
kubectl get secret SECRET_NAME -n NAMESPACE -o jsonpath='{.data.KEY}' | base64 -d
```

### Edit Secret

```bash
kubectl edit secret SECRET_NAME -n NAMESPACE
```

**Note**: Values must be base64 encoded when editing manually.

## Backup and Recovery

### Backup Secrets

```bash
# Backup all secrets in a namespace
kubectl get secrets -n NAMESPACE -o yaml > secrets-backup.yaml

# IMPORTANT: Store securely, NOT in Git!
```

### Restore Secrets

```bash
kubectl apply -f secrets-backup.yaml
```

## Compliance and Audit

### List All Secrets

```bash
# All secrets in cluster
kubectl get secrets -A

# Secrets in specific namespace
kubectl get secrets -n NAMESPACE
```

### Audit Secret Access

```bash
# View who has access to secrets
kubectl get rolebindings,clusterrolebindings -A -o json | \
  jq '.items[] | select(.roleRef.kind=="Role" or .roleRef.kind=="ClusterRole") |
      select(.subjects != null) |
      {name: .metadata.name, namespace: .metadata.namespace, subjects: .subjects}'
```

### Check Secret Age

```bash
kubectl get secrets -n NAMESPACE -o json | \
  jq -r '.items[] | "\(.metadata.name): \(.metadata.creationTimestamp)"'
```

## Support

For questions or issues with secret management:
1. Review this document
2. Check troubleshooting section
3. Review relevant tool documentation (cert-manager, Flux, Kubernetes)

---

**Last Updated**: 2025-11-03
**Security Level**: Production
