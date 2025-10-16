#!/usr/bin/env bash
set -e

HOSTNAME="ghostwire-dev.local"
PORT="6901"

echo "🌐 Setting up local access simulation for Ghostwire..."

# Check if /etc/hosts entry exists
if ! grep -q "$HOSTNAME" /etc/hosts 2>/dev/null; then
  echo "Adding $HOSTNAME to /etc/hosts (requires sudo)..."
  echo "127.0.0.1 $HOSTNAME" | sudo tee -a /etc/hosts > /dev/null
  echo "✅ Added $HOSTNAME to /etc/hosts"
else
  echo "✅ $HOSTNAME already in /etc/hosts"
fi

# Kill existing port forward if running
pkill -f "kubectl.*port-forward.*ghostwire" 2>/dev/null || true

# Start port forward in background
echo "Starting port-forward on 127.0.0.1:${PORT}..."
kubectl port-forward -n ghostwire svc/ghostwire-proxy ${PORT}:6901 --address 127.0.0.1 > /tmp/ghostwire-port-forward.log 2>&1 &
PF_PID=$!

# Wait for port forward to be ready
sleep 3

if ps -p $PF_PID > /dev/null; then
  echo "✅ Port forward running (PID: $PF_PID)"
  echo ""
  echo "🎉 Local access configured!"
  echo ""
  echo "Access Ghostwire at:"
  echo "  🔗 http://${HOSTNAME}:${PORT}"
  echo "  🔗 http://127.0.0.1:${PORT}"
  echo ""
  echo "Credentials:"
  echo "  Username: kasm_user"
  echo "  Password: testpass123"
  echo ""
  echo "To stop port-forward: pkill -f 'kubectl.*port-forward.*ghostwire'"
else
  echo "❌ Failed to start port forward"
  exit 1
fi
