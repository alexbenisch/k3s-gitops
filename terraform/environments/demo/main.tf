terraform {
  required_version = ">= 1.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

provider "hcloud" {
  token = var.hetzner_token
}

# SSH Key - use existing key from Hetzner
data "hcloud_ssh_key" "default" {
  name = "alex@tpad"
}

# Network
resource "hcloud_network" "k3s_network" {
  name     = "k3s-network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "k3s_subnet" {
  network_id   = hcloud_network.k3s_network.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

# Firewall
resource "hcloud_firewall" "k3s_firewall" {
  name = "k3s-firewall"

  # SSH
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  # HTTP
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  # HTTPS
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  # Kubernetes API
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "6443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  # Allow internal cluster communication
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "any"
    source_ips = [
      "10.0.0.0/16"
    ]
  }

  rule {
    direction = "in"
    protocol  = "udp"
    port      = "any"
    source_ips = [
      "10.0.0.0/16"
    ]
  }
}

# Master Node
resource "hcloud_server" "master" {
  name        = "k3s-master"
  image       = var.os_image
  server_type = var.master_server_type
  location    = var.location
  ssh_keys    = [data.hcloud_ssh_key.default.id]
  firewall_ids = [hcloud_firewall.k3s_firewall.id]

  network {
    network_id = hcloud_network.k3s_network.id
    ip         = "10.0.1.10"
  }

  labels = {
    role = "master"
    environment = "demo"
  }

  depends_on = [hcloud_network_subnet.k3s_subnet]
}

# Worker Nodes
resource "hcloud_server" "worker" {
  count       = var.worker_count
  name        = "k3s-worker-${count.index + 1}"
  image       = var.os_image
  server_type = var.worker_server_type
  location    = var.location
  ssh_keys    = [data.hcloud_ssh_key.default.id]
  firewall_ids = [hcloud_firewall.k3s_firewall.id]

  network {
    network_id = hcloud_network.k3s_network.id
    ip         = "10.0.1.${20 + count.index}"
  }

  labels = {
    role = "worker"
    environment = "demo"
  }

  depends_on = [hcloud_network_subnet.k3s_subnet]
}
