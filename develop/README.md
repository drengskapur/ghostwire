# Dev Environment

Local development environment for Ghostwire application testing.

## Overview

This directory contains k3s configuration for local development, suitable for:
- **k3d clusters** (k3s in Docker) - quick local testing
- **VM/bare metal k3s** - more production-like environment

**Environment:** Development
**Purpose:** Local testing of Ghostwire Helm chart and GitOps configuration

## k3d (Docker-based) Setup

### Prerequisites

- k3d installed (`brew install k3d` or see https://k3d.io)
- kubectl installed
- Docker Desktop running
- At least 4GB RAM available

### Quick Start

```bash
# Create k3d cluster with config
k3d cluster create ghostwire \
  --k3s-arg "--disable=traefik@server:*" \
  --k3s-arg "--disable=servicelb@server:*" \
  --port "80:80@loadbalancer" \
  --port "443:443@loadbalancer" \
  --port "6901:30901@loadbalancer"

# Verify cluster is running
kubectl cluster-info
kubectl get nodes
```

**Note:** k3d doesn't use the config.yaml file - it has its own configuration format. The config.yaml is for VM/bare metal k3s installations.

### Access Configuration

The cluster automatically updates your kubeconfig and switches context.

```bash
# Check current context
kubectl config current-context

# Switch to k3d cluster if needed
kubectl config use-context k3d-ghostwire
```

## k3s (VM/Bare Metal) Setup

For a more production-like environment using k3s on a VM or bare metal:

### Prerequisites

- Ubuntu/Debian-based system (or any Linux distro)
- Root/sudo access
- 4GB RAM minimum

### Installation

```bash
# Install k3s
curl -sfL https://get.k3s.io | sh -

# Copy config.yaml to k3s directory
sudo mkdir -p /etc/rancher/k3s
sudo cp config.yaml /etc/rancher/k3s/config.yaml

# Restart k3s to apply config
sudo systemctl restart k3s

# Get kubeconfig
sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config
chmod 600 ~/.kube/config

# Verify
kubectl get nodes
```

### What config.yaml does

The `config.yaml` file configures k3s to:
- Write kubeconfig with read permissions (0644)
- Disable traefik (for manual ingress control)
- Disable servicelb (for manual LoadBalancer setup)
- Enable cluster-init mode
- Add localhost to TLS SANs for API access

This matches the production droplet configuration for consistency.

## Port Configuration

### k3d Cluster Ports

When using k3d, ports are mapped from host to cluster:

- **80** → HTTP ingress (LoadBalancer)
- **443** → HTTPS ingress (LoadBalancer)
- **6901** → Signal VNC (mapped to NodePort 30901)

### k3s (VM) Ports

When using k3s on VM/bare metal:

- **6443** → Kubernetes API
- **30901** → Signal VNC (NodePort)
- Configure ingress controller separately for ports 80/443

## Development Workflow

### 1. Deploy Ghostwire Helm Chart

```bash
# Add oauth2-proxy dependency
cd ~/ghostwire/chart
helm dependency update

# Install chart locally
helm install ghostwire . \
  --namespace ghostwire \
  --create-namespace \
  --set service.type=NodePort \
  --set service.nodePort=30901

# Access Ghostwire VNC
open http://localhost:6901
```

### 2. Test with Flux (GitOps)

If you want to test the full Flux GitOps workflow locally:

```bash
# Bootstrap Flux (one-time setup)
flux bootstrap github \
  --owner=drengskapur \
  --repository=fleet-infra \
  --branch=main \
  --path=clusters/k3d-k3s-ghostwire \
  --personal

# Flux will automatically sync configurations from this directory
```

### 3. Test Configuration Changes

```bash
# Make changes to HelmRelease or other configs in this directory
# Commit and push changes

# Force immediate reconciliation
flux reconcile source git flux-system
flux reconcile kustomization flux-system
```

## Service Access

### Direct Access (without ingress)

```bash
# Port-forward to Ghostwire service
kubectl port-forward -n ghostwire svc/ghostwire 6901:6901

# Open browser
open http://localhost:6901
```

### With Ingress

```bash
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# Wait for ingress to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Access via ingress (configure ingress.enabled=true in values)
open http://localhost
```

## Cluster Management

### Stop Cluster

```bash
k3d cluster stop ghostwire
```

### Start Cluster

```bash
k3d cluster start ghostwire
```

### Delete Cluster

```bash
k3d cluster delete ghostwire
```

### Recreate Cluster

```bash
# Delete and recreate from config
k3d cluster delete ghostwire
k3d cluster create --config k3d-config.yaml
```

## Troubleshooting

### Cluster Won't Start

```bash
# Check Docker is running
docker ps

# Check k3d logs
k3d cluster list
docker logs k3d-ghostwire-server-0
```

### Port Already in Use

If port 6901 is already in use, edit `k3d-config.yaml` and change:

```yaml
ports:
  - port: 6902:30901  # Changed from 6901
```

### Out of Resources

```bash
# Reduce resource limits in Helm values
helm upgrade ghostwire ~/ghostwire/chart \
  --namespace ghostwire \
  --set resources.limits.cpu=500m \
  --set resources.limits.memory=1Gi
```

## Configuration Files

- `k3d-config.yaml` - k3d cluster configuration
- `flux-system/` - Flux GitOps configuration (if using Flux)
- `README.md` - This file

## Differences from Production

| Feature | Development (k3d) | Production (DO droplet) |
|---------|------------------|------------------------|
| Cluster | k3d local | k3s on droplet |
| Ingress | NodePort/localhost | LoadBalancer with reserved IP |
| Resources | Minimal (1-2Gi RAM) | Production sizing (4Gi RAM) |
| Storage | Local volumes | DigitalOcean volumes |
| TLS | Self-signed/none | Let's Encrypt (optional) |
| Access | localhost:6901 | Public IP/domain |

## Next Steps

After testing locally:

1. Commit configuration changes to git
2. Test in production-like environment (optional)
3. Deploy to production cluster: `clusters/do-nyc3-ghostwire/`

## References

- k3d Documentation: https://k3d.io
- Ghostwire Chart: ~/ghostwire/chart
- Production Cluster: ../do-nyc3-ghostwire/
