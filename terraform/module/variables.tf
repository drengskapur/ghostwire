variable "name" {
  description = "Name of the Ghostwire deployment"
  type        = string
  default     = "ghostwire1"
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc3"
}

variable "size" {
  description = "Droplet size/plan"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "image" {
  description = "Droplet image"
  type        = string
  default     = "ubuntu-24-04-x64"
}

variable "github_token" {
  description = "GitHub token for Flux bootstrap and GHCR authentication"
  type        = string
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "enable_monitoring" {
  description = "Enable DigitalOcean monitoring"
  type        = bool
  default     = true
}

variable "enable_backups" {
  description = "Enable automatic backups (adds 20% to cost)"
  type        = bool
  default     = false
}

variable "prevent_destroy" {
  description = "Prevent accidental destruction"
  type        = bool
  default     = false
}

variable "project_id" {
  description = "DigitalOcean project ID (optional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for the droplet"
  type        = list(string)
  default     = ["gitops", "k3s", "ghostwire"]
}

variable "ssh_allowed_ips" {
  description = "List of IP addresses/CIDRs allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "k8s_api_allowed_ips" {
  description = "List of IP addresses/CIDRs allowed for Kubernetes API access"
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "firewall_rules" {
  description = "Additional custom firewall inbound rules"
  type = list(object({
    protocol         = string
    port_range       = string
    source_addresses = list(string)
  }))
  default = []
}

variable "cloud_init_template" {
  description = "Path to cloud-init template (optional, uses default if not provided)"
  type        = string
  default     = ""
}
