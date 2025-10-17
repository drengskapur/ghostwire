# Ghostwire Tools

Comprehensive toolkit for Ghostwire deployments, based on Chainguard's Wolfi base image.

## Overview

This container provides a comprehensive set of tools for debugging Kubernetes deployments, networking issues, and general troubleshooting within the Ghostwire environment.

## Installed Tools

### Kubernetes
- `kubectl` - Kubernetes command-line tool
- `helm` - Kubernetes package manager

### Networking
- `curl` - Transfer data with URLs
- `wget` - Network downloader
- `iputils` - IP utilities (ping, traceroute)
- `bind-tools` - DNS utilities (dig, nslookup)
- `netcat-openbsd` - TCP/UDP connections and listening
- `tcpdump` - Network packet analyzer
- `nmap` - Network exploration and security auditing

### Development
- `bash` - GNU Bourne-Again Shell
- `vim` - Text editor
- `git` - Version control
- `python-3.12` - Python interpreter
- `jq` - JSON processor

### Container & System
- `docker-cli` - Docker command-line interface
- `procps` - Process utilities (ps, top)
- `htop` - Interactive process viewer
- `openssl` - Cryptography and SSL/TLS toolkit

## Usage

### Pull from GitHub Container Registry

```bash
# Latest development build (main branch)
docker pull ghcr.io/drengskapur/ghostwire/tools:latest

# Specific commit from main branch
docker pull ghcr.io/drengskapur/ghostwire/tools:0.0.0-main.<sha>

# Latest stable release
docker pull ghcr.io/drengskapur/ghostwire/tools:0.0.0-latest-stable

# Specific semantic version
docker pull ghcr.io/drengskapur/ghostwire/tools:1.0.0
```

### Run Locally

```bash
# Interactive shell
docker run -it --rm ghcr.io/drengskapur/ghostwire/tools:latest

# Run with Kubernetes config mounted
docker run -it --rm \
  -v ~/.kube:/root/.kube:ro \
  ghcr.io/drengskapur/ghostwire/tools:latest
```

### Deploy to Kubernetes

```bash
# Quick debug pod
kubectl run debug \
  --image=ghcr.io/drengskapur/ghostwire/tools:latest \
  --rm -it \
  --restart=Never \
  -- bash

# With specific namespace
kubectl run debug \
  -n ghostwire \
  --image=ghcr.io/drengskapur/ghostwire/tools:latest \
  --rm -it \
  --restart=Never \
  -- bash
```

### Example Troubleshooting Commands

```bash
# Test DNS resolution
nslookup ghostwire.ghostwire.svc.cluster.local

# Check network connectivity
curl -v http://ghostwire:6901

# Inspect running pods
kubectl get pods -n ghostwire

# View logs
kubectl logs -n ghostwire ghostwire-0

# Network packet capture
tcpdump -i any -n host ghostwire

# Port scanning
nmap -p 6901 ghostwire
```

## Versioning

This image follows the D2 (Deterministic Deployment) versioning pattern:

- **`0.0.0-main.<sha>`** - Development builds from main branch (per commit)
- **`0.0.0-latest`** - Latest development build (aliases to latest main)
- **`X.Y.Z`** - Semantic versioned releases (based on conventional commits)
- **`0.0.0-latest-stable`** - Latest stable release

All images are signed with Cosign for supply chain security.

## Building

```bash
# Build locally
docker build -t ghostwire/tools images/tools/

# Multi-platform build
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ghostwire/tools \
  images/tools/
```

## Base Image

Built on [Chainguard's Wolfi base image](https://images.chainguard.dev/directory/image/wolfi-base/overview) for:
- Minimal attack surface
- No CVEs in base image
- Regular security updates
- Declarative package management with `apk`

## License

Apache 2.0 - See [LICENSE](../../LICENSE) for details.
