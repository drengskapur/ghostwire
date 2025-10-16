terraform {
  required_version = ">= 1.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# SSH key for droplet access
resource "digitalocean_ssh_key" "this" {
  name       = "${var.name}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

# Droplet resource
resource "digitalocean_droplet" "this" {
  name   = "droplet-${var.name}"
  region = var.region
  size   = var.size
  image  = var.image

  ssh_keys = [digitalocean_ssh_key.this.fingerprint]

  # k3d installation script with GitHub token for Flux bootstrap
  user_data = var.cloud_init_template != "" ? templatefile(var.cloud_init_template, {
    github_token = var.github_token
  }) : templatefile("${path.module}/cloud-init.yaml", {
    github_token = var.github_token
  })

  tags = var.tags

  # Enable monitoring (free)
  monitoring = var.enable_monitoring

  # Enable automatic backups (adds 20% to cost)
  backups = var.enable_backups

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}

# Firewall for the droplet
resource "digitalocean_firewall" "this" {
  name = "${var.name}-firewall"

  droplet_ids = [digitalocean_droplet.this.id]

  # Dynamic inbound rules
  dynamic "inbound_rule" {
    for_each = var.firewall_rules
    content {
      protocol         = inbound_rule.value.protocol
      port_range       = inbound_rule.value.port_range
      source_addresses = inbound_rule.value.source_addresses
    }
  }

  # Allow all outbound
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# Reserved IP (stable IP address that persists across droplet replacements)
resource "digitalocean_reserved_ip" "this" {
  region = digitalocean_droplet.this.region
}

# Assign reserved IP to droplet
resource "digitalocean_reserved_ip_assignment" "this" {
  ip_address = digitalocean_reserved_ip.this.ip_address
  droplet_id = digitalocean_droplet.this.id
}

# Assign droplet to project (optional)
resource "digitalocean_project_resources" "this" {
  count   = var.project_id != null ? 1 : 0
  project = var.project_id
  resources = [
    digitalocean_droplet.this.urn,
    digitalocean_reserved_ip.this.urn
  ]
}
