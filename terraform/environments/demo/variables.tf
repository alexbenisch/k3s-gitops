variable "hetzner_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key for server access"
  type        = string
}

variable "location" {
  description = "Hetzner datacenter location"
  type        = string
  default     = "nbg1"  # Nuremberg
}

variable "os_image" {
  description = "Operating system image"
  type        = string
  default     = "ubuntu-22.04"
}

variable "master_server_type" {
  description = "Server type for master node"
  type        = string
  default     = "cx22"  # 2 vCPU, 4 GB RAM
}

variable "worker_server_type" {
  description = "Server type for worker nodes"
  type        = string
  default     = "cx22"  # 2 vCPU, 4 GB RAM
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}
