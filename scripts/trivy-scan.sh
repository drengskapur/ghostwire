#!/usr/bin/env bash
set -euo pipefail

# Run Trivy security scans on the Ghostwire project
# Scans: repository filesystem, Helm chart config, and container images

cd "$(dirname "$0")/.."

# Check if Trivy is installed, install if not
if ! command -v trivy &> /dev/null; then
  echo "⚠️  Trivy not found. Installing..."

  # Install to ~/.local/bin to avoid needing sudo
  mkdir -p ~/.local/bin
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b ~/.local/bin

  # Add to PATH if not already there
  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
  fi

  echo "✅ Trivy installed to ~/.local/bin/trivy"
fi

TRIVY=$(command -v trivy)

echo "🔍 Running Trivy security scans..."
echo ""

# 1. Scan repository filesystem for vulnerabilities
echo "📁 Scanning repository for vulnerabilities..."
$TRIVY fs --severity HIGH,CRITICAL --exit-code 0 .
REPO_RESULT=$?
echo ""

# 2. Scan Helm chart for misconfigurations
echo "⎈ Scanning Helm chart for misconfigurations..."
$TRIVY config --severity HIGH,CRITICAL --exit-code 0 chart/
CONFIG_RESULT=$?
echo ""

# 3. Scan container images referenced in values.yaml
echo "🐳 Scanning container images..."
IMAGE=$(grep 'repository:' chart/values.yaml | awk '{print $2}' | tr -d '"')
TAG=$(grep 'tag:' chart/values.yaml | awk '{print $2}' | tr -d '"')

if [ -n "$IMAGE" ] && [ -n "$TAG" ]; then
  echo "   Scanning $IMAGE:$TAG..."
  $TRIVY image --severity HIGH,CRITICAL --exit-code 0 "$IMAGE:$TAG"
  IMAGE_RESULT=$?
else
  echo "   ⚠️  Could not determine image from values.yaml"
  IMAGE_RESULT=0
fi
echo ""

# 4. Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Scan Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $REPO_RESULT -eq 0 ] && [ $CONFIG_RESULT -eq 0 ] && [ $IMAGE_RESULT -eq 0 ]; then
  echo "✅ All scans completed successfully"
  echo ""
  echo "💡 Tip: Run with --severity MEDIUM to see more findings"
  exit 0
else
  echo "⚠️  Some scans found issues (see above)"
  echo ""
  echo "💡 Review the findings and remediate as needed"
  exit 1
fi
