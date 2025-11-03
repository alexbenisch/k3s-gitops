# Quick Setup Guide

This guide walks you through setting up the demo cluster for your interview.

## Step 1: Prepare Repository

1. Create a new GitHub repository (public or private)
2. Push this code to your repository:
```bash
git remote add origin https://github.com/YOUR_USERNAME/k3s-gitops.git
git branch -M main
git push -u origin main
```

## Step 2: Add GitHub Secrets

Navigate to: Settings > Secrets and Variables > Actions > New repository secret

Add these secrets:

### HETZNER_TOKEN
Your Hetzner Cloud API token
- Login to https://console.hetzner.cloud/
- Go to Security > API Tokens
- Generate new token with Read & Write permissions
- Copy and paste as secret

### SSH_PUBLIC_KEY
Your SSH public key for server access
```bash
cat ~/.ssh/id_rsa.pub
```
Copy the entire output and paste as secret

### SSH_PRIVATE_KEY
Your SSH private key for Ansible
```bash
cat ~/.ssh/id_rsa
```
Copy the entire output (including BEGIN and END lines) and paste as secret

**Note**: GitHub automatically provides `GITHUB_TOKEN` - no need to add it.

## Step 3: Configure DNS

1. Login to Hetzner DNS Console: https://dns.hetzner.com/
2. Add DNS Zone for `k8s-demo.de`
3. Note the nameservers provided (ns1.first-ns.de, etc.)
4. Update your domain registrar to use Hetzner nameservers

Wait 10-30 minutes for DNS propagation.

## Step 4: Provision Infrastructure

1. Go to your GitHub repository
2. Click "Actions" tab
3. Select "Provision K3s Cluster" workflow
4. Click "Run workflow"
5. Select "apply" from dropdown
6. Click "Run workflow"

This will:
- Create 3 servers on Hetzner Cloud (1 master, 2 workers)
- Configure networking and firewall
- Install K3s on all nodes
- Upload kubeconfig as artifact

**Duration**: ~5-10 minutes

## Step 5: Download Kubeconfig

1. After workflow completes, click on the workflow run
2. Scroll to "Artifacts" section
3. Download "kubeconfig" artifact
4. Extract and place in your home directory:
```bash
unzip kubeconfig.zip
mv kubeconfig ~/.kube/k3s-demo-config
export KUBECONFIG=~/.kube/k3s-demo-config
```

5. Test access:
```bash
kubectl get nodes
```

You should see 3 nodes (1 master, 2 workers).

## Step 6: Bootstrap Flux

1. Go to Actions > "Bootstrap Flux" workflow
2. Click "Run workflow"
3. Wait for completion (~3-5 minutes)

This will:
- Install Flux CD controllers
- Connect Flux to your GitHub repository
- Deploy Traefik ingress controller
- Deploy cert-manager with Hetzner DNS webhook
- Deploy wallabag and linkding applications

## Step 7: Configure DNS Records

Get your master node's public IP:
```bash
cd terraform/environments/demo
terraform output master_ip
```

Or from Hetzner Cloud Console.

Add these A records in Hetzner DNS:
- Name: `wallabag`, Type: A, Value: `<master_ip>`
- Name: `linkding`, Type: A, Value: `<master_ip>`

## Step 8: Verify Deployment

```bash
# Check all resources
kubectl get all -A

# Check Flux status
flux get all -A

# Check certificates (may take 2-5 minutes)
kubectl get certificate -A

# Wait for certificates to be ready
watch kubectl get certificate -A
```

## Step 9: Access Applications

Once certificates are issued (Status: True):

- **Wallabag**: https://wallabag.k8s-demo.de
- **Linkding**: https://linkding.k8s-demo.de

### Wallabag First Login
```bash
# Get initial credentials
kubectl logs -n wallabag -l app=wallabag | grep -i "admin"
```
Default: admin / wallabag

### Linkding First Login
First user to register becomes administrator.

## Verification Checklist

- [ ] All nodes are Ready: `kubectl get nodes`
- [ ] All Flux components running: `flux get all`
- [ ] Traefik is running: `kubectl get pods -n traefik`
- [ ] cert-manager is running: `kubectl get pods -n cert-manager`
- [ ] Certificates are ready: `kubectl get certificate -A`
- [ ] Applications are running: `kubectl get pods -n wallabag -n linkding`
- [ ] DNS resolves correctly: `dig wallabag.k8s-demo.de`
- [ ] HTTPS works: `curl https://wallabag.k8s-demo.de`

## Interview Talking Points

### What This Demonstrates

1. **Infrastructure as Code**
   - Terraform for cloud resources
   - Version-controlled infrastructure
   - Reproducible environments

2. **Configuration Management**
   - Ansible for server configuration
   - Role-based organization
   - Idempotent operations

3. **GitOps Methodology**
   - Flux for continuous delivery
   - Git as single source of truth
   - Automatic reconciliation

4. **Kubernetes Best Practices**
   - Namespace isolation
   - Resource management
   - Health checks and readiness probes
   - Persistent storage

5. **Security**
   - Automated TLS certificates
   - Network policies via firewall
   - Secret management
   - SSH key-based authentication

6. **CI/CD**
   - GitHub Actions workflows
   - Automated testing potential
   - Infrastructure deployment automation

### Demo Flow Suggestion

1. **Show Repository Structure** (2 min)
   - Explain organization
   - Highlight separation of concerns

2. **Show GitHub Actions** (3 min)
   - Walk through provision workflow
   - Explain how secrets are used
   - Show successful runs

3. **Show Flux Dashboard** (3 min)
   ```bash
   flux get all -A
   ```
   - Explain reconciliation
   - Show GitOps in action

4. **Show Running Applications** (3 min)
   - Browse to wallabag.k8s-demo.de
   - Browse to linkding.k8s-demo.de
   - Show TLS certificates

5. **Demonstrate Update** (4 min)
   - Edit replica count in Git
   - Commit and push
   - Show Flux auto-deploy
   ```bash
   watch kubectl get pods -n wallabag
   ```

6. **Q&A and Deep Dive** (remaining time)
   - Be ready to explain any component
   - Discuss scaling strategies
   - Talk about production considerations

## Troubleshooting

### Terraform Fails
- Check Hetzner API token
- Verify SSH key format
- Check Hetzner Cloud quotas

### Ansible Fails
- Verify SSH private key
- Check server accessibility
- Review Ansible logs in GitHub Actions

### Flux Not Deploying
```bash
flux logs
kubectl logs -n flux-system -l app=source-controller
```

### Certificates Not Issuing
```bash
kubectl describe certificate wallabag-tls -n wallabag
kubectl logs -n cert-manager -l app=cert-manager
```
- Verify Hetzner DNS API token
- Check DNS zone name matches
- Ensure DNS is properly configured

### Applications Not Accessible
- Check DNS propagation: `dig wallabag.k8s-demo.de`
- Check ingress: `kubectl get ingress -A`
- Check pods: `kubectl get pods -A`
- Check firewall rules in Hetzner Console

## Cleanup

When done with the demo:
```bash
# Via GitHub Actions
Actions > Provision K3s Cluster > Run workflow > destroy

# Or manually
cd terraform/environments/demo
terraform destroy
```

**Cost**: ~€0.01-0.02 per hour while running

## Next Steps (Optional Extensions)

- Add Prometheus/Grafana for monitoring
- Implement Velero for backups
- Add more applications
- Implement NetworkPolicies
- Add Horizontal Pod Autoscaling
- Integrate ArgoCD for comparison
