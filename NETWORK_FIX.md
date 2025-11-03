# K3S Network Configuration Fix

## Issue
Flux GitRepository was unable to sync from GitHub due to DNS timeout errors. Pods could not reach CoreDNS, causing DNS resolution failures.

## Root Cause
The k3s cluster nodes were using public IP addresses for inter-node communication instead of the private network (10.0.0.0/16). This caused:
- VXLAN/Flannel traffic to fail between nodes
- Pods on one node unable to communicate with pods on other nodes
- DNS queries timing out

## Solution
Configured all k3s nodes to use the private network interface (enp7s0) for cluster communication.

### Changes Made

#### Master Node (k3s-master)
File: `/etc/systemd/system/k3s.service`

Added parameters to ExecStart:
```bash
'--node-ip' \
'10.0.1.10' \
'--flannel-iface' \
'enp7s0' \
```

#### Worker Node 1 (k3s-worker-1)
File: `/etc/systemd/system/k3s-agent.service`

Added parameters to ExecStart:
```bash
'--node-ip' \
'10.0.1.20' \
'--flannel-iface' \
'enp7s0' \
```

#### Worker Node 2 (k3s-worker-2)
File: `/etc/systemd/system/k3s-agent.service`

Added parameters to ExecStart:
```bash
'--node-ip' \
'10.0.1.21' \
'--flannel-iface' \
'enp7s0' \
```

### Restart Procedure
After configuration changes on each node:
```bash
systemctl daemon-reload
systemctl restart k3s        # On master
systemctl restart k3s-agent  # On workers
```

For worker-2, a full re-registration was required:
```bash
systemctl stop k3s-agent
rm -rf /var/lib/rancher/k3s/agent
systemctl start k3s-agent
```

## Verification

### Node Status
```bash
kubectl get nodes -o wide
```
All nodes now show private IPs (10.0.1.x) as INTERNAL-IP.

### DNS Test
```bash
kubectl run test-dns --image=busybox --restart=Never -- nslookup github.com
```
DNS resolution now works successfully.

### Flux Status
```bash
kubectl get gitrepositories -n flux-system
```
GitRepository shows READY=True and successful sync.

## Network Topology
- Public Network: 88.99.124.124/32, 188.245.227.116/32, 91.99.11.208/32
- Private Network: 10.0.1.0/24 (via enp7s0)
- Pod Network (Flannel): 10.42.0.0/16 (VXLAN over private network)

## Date Fixed
2025-11-03
