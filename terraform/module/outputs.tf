output "reserved_ip" {
  description = "Reserved IP address (use this for DNS and connections)"
  value       = digitalocean_reserved_ip.this.ip_address
}

output "droplet_ip" {
  description = "Droplet's ephemeral IP (not used when reserved IP is assigned)"
  value       = digitalocean_droplet.this.ipv4_address
}

output "droplet_id" {
  description = "ID of the droplet"
  value       = digitalocean_droplet.this.id
}

output "droplet_urn" {
  description = "URN of the droplet"
  value       = digitalocean_droplet.this.urn
}

output "droplet_name" {
  description = "Name of the droplet"
  value       = digitalocean_droplet.this.name
}

output "region" {
  description = "Region of the droplet"
  value       = digitalocean_droplet.this.region
}

output "size" {
  description = "Size of the droplet"
  value       = digitalocean_droplet.this.size
}

output "ssh_command" {
  description = "SSH command to connect to droplet"
  value       = "ssh root@${digitalocean_reserved_ip.this.ip_address}"
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig from droplet"
  value       = "scp root@${digitalocean_reserved_ip.this.ip_address}:/etc/rancher/k3s/k3s.yaml ~/.kube/${var.name}-config"
}

output "firewall_id" {
  description = "ID of the firewall"
  value       = digitalocean_firewall.this.id
}

output "ssh_key_fingerprint" {
  description = "Fingerprint of the SSH key"
  value       = digitalocean_ssh_key.this.fingerprint
}
