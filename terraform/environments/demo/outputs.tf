output "master_ip" {
  description = "Public IP of the master node"
  value       = hcloud_server.master.ipv4_address
}

output "master_private_ip" {
  description = "Private IP of the master node"
  value       = hcloud_server.master.network[0].ip
}

output "worker_ips" {
  description = "Public IPs of worker nodes"
  value       = hcloud_server.worker[*].ipv4_address
}

output "worker_private_ips" {
  description = "Private IPs of worker nodes"
  value       = hcloud_server.worker[*].network[*].ip
}

output "network_id" {
  description = "Hetzner Cloud Network ID"
  value       = hcloud_network.k3s_network.id
}
