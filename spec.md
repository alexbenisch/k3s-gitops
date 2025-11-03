# 🧩 K3s Self-Hosting Cluster — Spec Sheet

## 🏗️ Architekturüberblick

| Komponente | Beschreibung |
|-------------|--------------|
| **Cluster-Typ** | Lightweight Kubernetes (K3s) |
| **Ziel** | Self-hosting von privaten Apps (Wallaby, Linkding, Miniflux, Immich etc.) |
| **Bereitstellung** | Manuell oder via Ansible/Terraform |
| **Netzwerk** | Flannel (Default), optional Cilium für Load Balancing & Security Policies |
| **Ingress** | Traefik (Standard in K3s), optional NGINX Ingress Controller |
| **Storage** | Longhorn oder lokale PersistentVolumes |
| **Backup** | Velero + S3-kompatibles Storage-Backend (z. B. MinIO) |

---

## ⚙️ Hardware / Nodes

| Rolle | CPU | RAM | Storage | OS | Beispiel |
|-------|-----|-----|----------|----|-----------|
| **Master** | 2 vCPU | 4 GB | 20 GB SSD | Fedora Server / Ubuntu Server | Hetzner CX22 |
| **Worker 1** | 2 vCPU | 4 GB | 50 GB SSD | Fedora Server / Ubuntu Server | Hetzner CX22 |
| **Worker 2** | 2 vCPU | 4 GB | 50 GB SSD | Fedora Server / Ubuntu Server | Hetzner CX22 |
| **Optional: NAS / Backup Node** | 2 vCPU | 2 GB | 500 GB HDD | Debian / TrueNAS | Lokales Gerät |

---

## 🔐 Sicherheit

- SSH-Zugang nur via Key (kein Passwort-Login)
- Firewall: nur Ports `22`, `80`, `443`, `6443`
- Cluster-Traffic intern über WireGuard-Mesh (optional via Tailscale)
- Secrets:
  - Verwaltung über `SealedSecrets` oder `SOPS + age`
  - Keine Klartext-API-Keys in Git-Repos
- Automatische Security Updates via `unattended-upgrades` oder `dnf-automatic`

---

## 🧰 Core Components

| Komponente | Zweck | Anmerkungen |
|-------------|--------|-------------|
| **k3s** | Kubernetes Distribution | `INSTALL_K3S_EXEC="--disable traefik"` falls eigener Ingress genutzt wird |
| **Helm** | Paketmanagement | Für App-Deployments |
| **Traefik / NGINX** | Ingress Controller | TLS mit Let’s Encrypt |
| **cert-manager** | Automatische Zertifikate | DNS- oder HTTP-01-Challenge |
| **Longhorn** | Persistenter Speicher | Einfach zu verwalten, UI verfügbar |
| **Prometheus + Grafana** | Monitoring & Dashboards | Ressourcenüberwachung |
| **Loki + Promtail** | Zentrales Logging | Optional mit Grafana integriert |
| **Velero + MinIO** | Backup & Restore | Disaster Recovery |

---

## 📦 Geplante Self-Hosted Apps

| App | Beschreibung | Deployment | Datenvolumen |
|------|---------------|-------------|---------------|
| **Linkding** | Bookmarks | Helm Chart oder K8s YAML | < 1 GB |
| **Wallaby** | Feed-Reader mit LLM-Support | Docker-Compose → Helm Migration | 2–3 GB |
| **Miniflux** | RSS Reader | Helm Chart | < 500 MB |
| **Immich** | Self-hosted Fotos | StatefulSet mit PVCs | 100–500 GB |
| **Plausible / Umami** | Web Analytics | Helm Chart | 1–5 GB |
| **Vaultwarden** | Passwortmanager | Helm Chart | < 1 GB |
| **Home Assistant** | Smart Home | Helm Chart | 2–10 GB |
| **MinIO** | S3-kompatibler Storage | Helm Chart | variabel |

---

## 🌐 DNS & Domains

| Zweck | Beispiel | Setup |
|--------|-----------|--------|
| **Hauptdomain** | `home.example.com` | A-Record → Public IP |
| **Wildcard Subdomain** | `*.home.example.com` | Für automatische Ingress-Hosts |
| **DNS Provider** | Cloudflare / DuckDNS | Unterstützt API-basierte Zertifikatsanforderung |

---

## 🪄 Deployment Automation

### Option A — Terraform + Ansible
- Terraform: Provisionierung der Hetzner-VMs
- Ansible: Installation von K3s, Helm, Longhorn, Traefik, Apps
- Vorteile: Wiederholbare, deklarative Cluster-Erstellung

### Option B — Manuell mit K3sup
```bash
k3sup install --ip <master_ip> --user alex
k3sup join --ip <worker_ip> --server-ip <master_ip> --user alex

