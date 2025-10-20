#!/bin/bash
set -e

echo "🚀 Setting up Ghostwire development environment..."

# Wait for Docker to be ready
echo "⏳ Waiting for Docker..."
timeout 30 bash -c 'until docker info >/dev/null 2>&1; do sleep 1; done' || {
    echo "❌ Docker failed to start"
    exit 1
}

# Create k3d cluster if it doesn't exist
if ! k3d cluster list | grep -q ghostwire-dev; then
    echo "📦 Creating k3d cluster..."
    k3d cluster create ghostwire-dev \
        --api-port 6550 \
        --port "6901:6901@loadbalancer" \
        --agents 1 \
        --wait
    
    echo "✅ k3d cluster created"
else
    echo "✅ k3d cluster already exists"
fi

# Set kubectl context
kubectl config use-context k3d-ghostwire-dev

# Create ghostwire namespace
kubectl create namespace ghostwire --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Development environment ready!"
echo ""
echo "📝 Quick commands:"
echo "  - Test locally: ./scripts/test-k3d-playwright.sh"
echo "  - Install chart: helm install ghostwire ./chart -n ghostwire"
echo "  - Access VNC: http://localhost:6901"
echo "  - Port forward: kubectl port-forward -n ghostwire svc/ghostwire 6901:6901"
