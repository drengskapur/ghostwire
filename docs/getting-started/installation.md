# Installation

Ghostwire installs via Helm and runs on any Kubernetes cluster with persistent volume support.

## Prerequisites

**Kubernetes 1.24+** with a working storage class for persistent volumes. Most managed Kubernetes services (GKE, EKS, AKS) provide this by default.

**Helm 3.x** for chart installation.

**4GB memory available** for the Signal Desktop pod. The default resource request is 2GB with a 4GB limit.

## Install from OCI Registry

The chart is published to GitHub Container Registry:

```bash
helm install ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  --version 0.0.0-latest \
  --create-namespace -n ghostwire
```

Pin to a specific version for production:

```bash
helm install ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  --version 1.0.0 \
  --create-namespace -n ghostwire
```

## Install from Artifact Hub

Add the repository:

```bash
helm repo add ghostwire https://drengskapur.github.io/ghostwire
helm repo update
```

Install:

```bash
helm install ghostwire ghostwire/ghostwire \
  --create-namespace -n ghostwire
```

## Verify Installation

Check the pod status:

```bash
kubectl get pods -n ghostwire
```

Wait for the pod to be ready:

```bash
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=ghostwire -n ghostwire --timeout=300s
```

## Local Development Cluster

For testing, use k3d to create a local cluster:

```bash
# Install k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Create cluster
k3d cluster create ghostwire

# Install chart
helm install ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  --version 0.0.0-latest \
  --create-namespace -n ghostwire
```

## Uninstall

Remove the release:

```bash
helm uninstall ghostwire -n ghostwire
```

The PVC is retained by default to preserve your Signal data. Delete it manually if needed:

```bash
kubectl delete pvc -l app.kubernetes.io/name=ghostwire -n ghostwire
```

## Next Steps

- [Quick Start](quickstart.md) — First access and Signal linking
- [Configuration](configuration.md) — Customize resources, persistence, and features
