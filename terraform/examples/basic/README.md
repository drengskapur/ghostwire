# Basic Ghostwire Deployment Example

This example demonstrates a basic Ghostwire deployment on DigitalOcean.

## Prerequisites

- Terraform >= 1.0
- DigitalOcean account and API token
- GitHub personal access token
- SSH key at `~/.ssh/id_ed25519.pub`

## Usage

1. **Set environment variables**:
   ```bash
   export DIGITALOCEAN_TOKEN="your_do_token"
   ```

2. **Configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your GitHub token
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan the deployment**:
   ```bash
   terraform plan
   ```

5. **Apply the deployment**:
   ```bash
   terraform apply
   ```

6. **Get outputs**:
   ```bash
   terraform output -raw ssh_command
   terraform output -raw reserved_ip
   ```

## What Gets Created

- 1x DigitalOcean Droplet (s-2vcpu-4gb, $24/month)
- 1x Reserved IP ($4/month)
- 1x Firewall (free)
- 1x SSH Key (free)

**Total Cost**: ~$28/month

## Post-Deployment

After deployment completes, wait for cloud-init to finish (~5-10 minutes):

```bash
ssh root@$(terraform output -raw reserved_ip) 'cloud-init status --wait'
```

Then get the kubeconfig:

```bash
$(terraform output -raw kubeconfig_command)
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Note**: The Reserved IP will be released and you'll get a different IP if you recreate.
