# Ghostwire Dev Container

This dev container provides a fully configured development environment for Ghostwire with:

## 🚀 What's Included

- **k3d** - Lightweight Kubernetes cluster (auto-created on startup)
- **kubectl** - Kubernetes CLI
- **Helm 3.14.0** - Package manager
- **Node.js 20** - JavaScript runtime
- **Playwright** - Browser automation (with Chromium pre-installed)
- **Docker-in-Docker** - For building/testing containers
- **Go 1.23** - Go toolchain

## 📦 Pre-cached Images

The following images are pre-pulled to speed up development:
- `rancher/k3s:v1.28.5-k3s1`
- `kasmweb/signal:1.0.0-rolling-daily`
- `mcr.microsoft.com/playwright:v1.40.0-jammy`

## 🎯 Quick Start

### VS Code (Local)
1. Install [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
2. Open this repo in VS Code
3. Click "Reopen in Container" when prompted
4. Wait for setup (first time takes ~5-10 minutes)

### VS Code (GitHub Codespaces)
1. Click "Code" → "Create codespace on main"
2. Wait for setup
3. Start developing!

## 🛠️ What Happens on Startup

The `setup.sh` script automatically:
1. Waits for Docker to be ready
2. Creates a k3d cluster named `ghostwire-dev`
3. Configures port forwards (6901 for VNC)
4. Creates `ghostwire` namespace
5. Sets kubectl context

## 🧪 Testing Locally

```bash
# Run integration tests
./scripts/test-k3d-playwright.sh

# Install Ghostwire chart
helm install ghostwire ./chart -n ghostwire

# Access VNC interface
# The port is auto-forwarded, just open: http://localhost:6901
```

## 🔧 Useful Commands

```bash
# Check cluster status
k3d cluster list
kubectl get nodes

# View Ghostwire pods
kubectl get pods -n ghostwire

# Port forward manually
kubectl port-forward -n ghostwire svc/ghostwire 6901:6901

# Restart cluster
k3d cluster delete ghostwire-dev
k3d cluster create ghostwire-dev --port "6901:6901@loadbalancer"
```

## 💾 Caching

The devcontainer image is cached to speed up rebuilds:
- **Docker images**: Pre-pulled during build
- **Playwright browsers**: Installed system-wide
- **Helm plugins**: Pre-installed
- **Node modules**: Will be cached in CI

## 🚀 CI/CD Integration

This same devcontainer can be used in GitHub Actions with:
- `devcontainers/ci` action
- Automatic image layer caching
- Consistent environment between local and CI

See `.github/workflows/` for examples.
