# GitHub Secrets Configuration

Before running the GitHub Actions workflows, you need to configure these secrets in your repository.

## How to Add Secrets

1. Go to your GitHub repository
2. Click **Settings** > **Secrets and variables** > **Actions**
3. Click **New repository secret**
4. Add each secret below

## Required Secrets

### 1. HETZNER_TOKEN

**Description**: Hetzner Cloud API Token for provisioning infrastructure

**How to get it**:
```bash
1. Login to https://console.hetzner.cloud/
2. Select your project (or create one)
3. Go to "Security" > "API Tokens"
4. Click "Generate API Token"
5. Name: "k3s-demo-cluster"
6. Permissions: Read & Write
7. Copy the token (shown only once!)
```

**Value**: `your-hetzner-api-token-here`

---

### 2. SSH_PUBLIC_KEY

**Description**: Your SSH public key for server access

**How to get it**:
```bash
# If you already have an SSH key
cat ~/.ssh/id_rsa.pub

# If you need to generate one
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
cat ~/.ssh/id_rsa.pub
```

**Value**: Entire output, should look like:
```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... your-email@example.com
```

---

---

**Note**: SSH_PRIVATE_KEY is NOT needed! Ansible runs from your local machine and uses your local SSH key to connect to the servers. Only the public key needs to be added to the servers (done by Terraform).

---

### 4. GITHUB_TOKEN

**Description**: GitHub Personal Access Token for Flux to access the repository

**Status**: ✅ **Automatically provided by GitHub Actions**

You don't need to create this secret manually. GitHub automatically provides `secrets.GITHUB_TOKEN` to workflows.

However, if Flux bootstrap needs additional permissions, create a Personal Access Token:

1. Go to https://github.com/settings/tokens
2. Generate new token (classic)
3. Name: "flux-gitops"
4. Scopes: `repo` (all)
5. Generate and copy the token

---

## Verification Checklist

Before running workflows, verify:

- [ ] HETZNER_TOKEN is set
- [ ] SSH_PUBLIC_KEY is set (starts with `ssh-rsa`)
- [ ] SSH_PRIVATE_KEY is set (starts with `-----BEGIN`)
- [ ] All values are pasted correctly without extra spaces

## Testing Secrets Locally (Optional)

If you want to test Terraform locally before pushing:

```bash
# Copy the example file
cp .env.example .env

# Edit with your values
vim .env

# Source the variables
source .env

# Test Terraform
cd terraform/environments/demo
terraform init
terraform plan
```

**Remember**: Never commit `.env` file - it's in `.gitignore`

## Security Notes

### What's Safe to Share
✅ Hetzner Token - scoped to your project only
✅ SSH Public Key - safe to share (it's public!)

### What to Keep Secret
❌ SSH Private Key - NEVER share or commit
❌ GitHub Token - personal access token
❌ Any generated kubeconfig files

### Revoking Access

If you accidentally expose a secret:

**Hetzner Token**:
1. Go to Hetzner Console > Security > API Tokens
2. Delete the exposed token
3. Generate a new one
4. Update GitHub secret

**SSH Key**:
1. Generate new SSH key pair
2. Update GitHub secrets
3. Update Hetzner Cloud SSH keys
4. Remove old key from `~/.ssh/authorized_keys` on any servers

**GitHub Token**:
1. Go to https://github.com/settings/tokens
2. Revoke the exposed token
3. Generate new token
4. Update GitHub secret

## Common Issues

### Issue: "Invalid API token"
**Solution**: Regenerate token in Hetzner Console, ensure Read & Write permissions

### Issue: "Permission denied (publickey)"
**Solution**: Verify SSH_PUBLIC_KEY matches SSH_PRIVATE_KEY pair

### Issue: "Flux bootstrap fails with 403"
**Solution**: Create personal GitHub token with `repo` scope

### Issue: "Rate limit exceeded"
**Solution**: Use personal GitHub token instead of automatic GITHUB_TOKEN

## Next Steps

After configuring secrets:
1. Read [SETUP.md](SETUP.md) for deployment instructions
2. Run "Provision K3s Cluster" workflow
3. Run "Bootstrap Flux" workflow
4. Check [INTERVIEW_GUIDE.md](INTERVIEW_GUIDE.md) for demo preparation
