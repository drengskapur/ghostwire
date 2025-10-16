# Ghostwire Terraform Module

Terraform module for deploying Ghostwire (Signal Desktop) on DigitalOcean with k3s, FluxCD, and GitOps.

## Features

- ✅ DigitalOcean Droplet with k3s pre-installed
- ✅ Reserved IP for stable addressing
- ✅ Firewall with sensible defaults
- ✅ Cloud-init for automated setup
- ✅ FluxCD GitOps ready
- ✅ SSH key management
- ✅ Optional project assignment
- ✅ Customizable firewall rules
- ✅ Monitoring and backup options

## Usage

### Basic Example

```hcl
module "ghostwire" {
  source = "./module"

  name         = "ghostwire1"
  region       = "nyc3"
  github_token = var.github_token
}

output "ssh_command" {
  value = module.ghostwire.ssh_command
}

output "reserved_ip" {
  value = module.ghostwire.reserved_ip
}
```

### Advanced Example

```hcl
module "ghostwire_prod" {
  source = "./module"

  name   = "ghostwire-prod"
  region = "sfo3"
  size   = "s-4vcpu-8gb"

  github_token         = var.github_token
  ssh_public_key_path  = "~/.ssh/ghostwire.pub"

  enable_monitoring = true
  enable_backups    = true
  prevent_destroy   = true

  project_id = "5728d115-9838-48cf-9d5a-8e3ad61444b6"

  tags = ["production", "gitops", "ghostwire"]

  # Custom firewall rules - restrict SSH to your IP
  firewall_rules = [
    {
      protocol         = "tcp"
      port_range       = "22"
      source_addresses = ["YOUR.IP.ADDRESS/32"]
    },
    {
      protocol         = "tcp"
      port_range       = "80"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "443"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "6443"
      source_addresses = ["YOUR.IP.ADDRESS/32"]
    }
  ]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| digitalocean | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| digitalocean | ~> 2.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the Ghostwire deployment | `string` | `"ghostwire1"` | no |
| region | DigitalOcean region | `string` | `"nyc3"` | no |
| size | Droplet size/plan | `string` | `"s-2vcpu-4gb"` | no |
| image | Droplet image | `string` | `"ubuntu-24-04-x64"` | no |
| github_token | GitHub token for Flux bootstrap and GHCR | `string` | n/a | yes |
| ssh_public_key_path | Path to SSH public key | `string` | `"~/.ssh/id_ed25519.pub"` | no |
| enable_monitoring | Enable DigitalOcean monitoring | `bool` | `true` | no |
| enable_backups | Enable automatic backups (+20% cost) | `bool` | `false` | no |
| prevent_destroy | Prevent accidental destruction | `bool` | `false` | no |
| project_id | DigitalOcean project ID | `string` | `null` | no |
| tags | Tags for the droplet | `list(string)` | `["gitops", "k3s", "ghostwire"]` | no |
| firewall_rules | Custom firewall inbound rules | `list(object)` | See defaults | no |
| cloud_init_template | Path to custom cloud-init template | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| reserved_ip | Reserved IP address |
| droplet_id | ID of the droplet |
| droplet_name | Name of the droplet |
| ssh_command | SSH command to connect |
| kubeconfig_command | Command to get kubeconfig |
| firewall_id | ID of the firewall |

## Post-Deployment

After the droplet is created:

1. **Wait for cloud-init to complete** (~5-10 minutes):
   ```bash
   ssh root@<reserved_ip> 'cloud-init status --wait'
   ```

2. **Get the kubeconfig**:
   ```bash
   scp root@<reserved_ip>:/etc/rancher/k3s/k3s.yaml ~/.kube/ghostwire-config
   # Update server address
   sed -i 's/127.0.0.1/<reserved_ip>/' ~/.kube/ghostwire-config
   ```

3. **Bootstrap FluxCD** (if not done by cloud-init):
   ```bash
   flux bootstrap github \
     --owner=<your-org> \
     --repository=<your-repo> \
     --branch=main \
     --path=./cluster \
     --personal
   ```

## Cost Estimation

- **Droplet**: $24/month (s-2vcpu-4gb)
- **Reserved IP**: $4/month
- **Backups** (optional): +20% ($4.80/month)
- **Total**: ~$28-33/month

## License

MIT
