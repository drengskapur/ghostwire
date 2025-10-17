# Ghostwire Terraform Configuration

Simplified Terraform configuration for deploying Ghostwire on DigitalOcean with k3d and Flux GitOps.

## Quick Start

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply configuration
terraform apply
```

## What Gets Deployed

This Terraform configuration creates:

- **DigitalOcean Droplet** running Ubuntu 24.04
- **k3d cluster** (Kubernetes in Docker)
- **Flux GitOps** bootstrapped to your fleet-infra repository
- **Firewall rules** for SSH, HTTPS, and Kubernetes API access
- **Automatic deployment** of Ghostwire via Flux

## Required Variables

- `github_token` - GitHub Personal Access Token with repo and packages permissions
- `ssh_public_key_path` - Path to your SSH public key

## Important Files

- `main.tf` - Core Terraform resources (droplet, firewall, SSH key)
- `variables.tf` - Input variable definitions
- `outputs.tf` - Output values (IP addresses, connection info)
- `versions.tf` - Provider version constraints
- `cloud-init.yaml` - Cloud-init configuration for automated setup
- `terraform.tfvars.example` - Example configuration file
- `.terraform-docs.yml` - Terraform documentation generator config
- `.tflint.hcl` - Terraform linting configuration

## Firewall Configuration

By default, the firewall allows:
- **SSH** (port 22) from configured IPs
- **HTTPS** (port 443) from anywhere
- **Kubernetes API** (port 6443) from configured IPs

Customize via `ssh_allowed_ips`, `k8s_api_allowed_ips`, and `firewall_rules` variables.

## Cloud-Init Process

The cloud-init configuration (`cloud-init.yaml`):

1. Creates ubuntu user with Docker access
2. Installs Docker, k3d, kubectl, and Flux CLI
3. Creates k3d cluster with NodePort mapping (443:30080)
4. Bootstraps Flux to your fleet-infra repository
5. Waits for Ghostwire deployment to be ready

Logs are available at `/var/log/user-data.log` on the droplet.

## Accessing Your Deployment

After deployment completes:

```bash
# SSH to droplet
ssh ubuntu@<droplet_ip>

# Access Ghostwire via HTTPS
https://<droplet_ip>

# Check deployment status
kubectl get pods -n ghostwire
flux get all
```

## Customization

### Custom Cloud-Init

Provide your own cloud-init template:

```hcl
cloud_init_template = "./my-custom-init.yaml"
```

### Additional Firewall Rules

```hcl
firewall_rules = [
  {
    protocol         = "tcp"
    port_range       = "8080"
    source_addresses = ["203.0.113.0/24"]
  }
]
```

### Resource Options

```hcl
enable_monitoring = true   # Enable DigitalOcean monitoring
enable_backups    = true   # Enable weekly backups
prevent_destroy   = true   # Prevent accidental deletion
```

## Cleanup

```bash
# Destroy all resources
terraform destroy
```

**Warning:** This will permanently delete the droplet and all data.
