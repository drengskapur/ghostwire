terraform {
  required_version = ">= 1.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  # Token will be read from DIGITALOCEAN_TOKEN env var
}

variable "github_token" {
  description = "GitHub token for Flux bootstrap and GHCR authentication"
  type        = string
  sensitive   = true
}

module "ghostwire" {
  source = "../../module"

  name         = "ghostwire1"
  region       = "nyc3"
  github_token = var.github_token
}

output "ssh_command" {
  description = "SSH command to connect to droplet"
  value       = module.ghostwire.ssh_command
}

output "reserved_ip" {
  description = "Reserved IP address"
  value       = module.ghostwire.reserved_ip
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig"
  value       = module.ghostwire.kubeconfig_command
}
