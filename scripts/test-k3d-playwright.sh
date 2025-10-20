#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-k3s-default}"
NAMESPACE="${NAMESPACE:-ghostwire}"
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/test-results"
SCREENSHOT_DIR="${TEST_DIR}/screenshots"

cleanup() {
    log "Cleaning up..."
    kubectl delete namespace "${NAMESPACE}" --ignore-not-found=true 2>/dev/null || true
    docker rm -f playwright-test 2>/dev/null || true
    pkill -f "port-forward.*ghostwire" 2>/dev/null || true
}

trap cleanup EXIT

main() {
    log "Using existing k3d cluster or creating default..."
    if ! k3d cluster list | grep -q "${CLUSTER_NAME}"; then
        k3d cluster create
    fi

    log "Waiting for cluster to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=120s

    log "Creating namespace..."
    kubectl create namespace "${NAMESPACE}"

    log "Installing Ghostwire via Helm..."
    helm upgrade --install ghostwire ./chart \
        --namespace "${NAMESPACE}" \
        --wait --timeout=5m \
        --debug

    log "Waiting for Ghostwire pod to be ready..."
    kubectl wait --for=condition=Ready pod \
        -l app.kubernetes.io/name=ghostwire \
        -n "${NAMESPACE}" \
        --timeout=300s

    log "Getting Ghostwire service details..."
    kubectl get svc -n "${NAMESPACE}"
    
    # Start port-forward in background
    log "Starting port-forward..."
    kubectl port-forward -n "${NAMESPACE}" svc/ghostwire 6901:6901 &
    PORT_FORWARD_PID=$!
    
    GHOSTWIRE_URL="http://localhost:6901"
    log "Ghostwire URL: ${GHOSTWIRE_URL}"

    log "Waiting for port-forward and Ghostwire to be accessible..."
    sleep 3
    for i in {1..30}; do
        if curl -s -o /dev/null "${GHOSTWIRE_URL}/?keyboard=1"; then
            log "Ghostwire is accessible"
            break
        fi
        if [ $i -eq 30 ]; then
            error "Ghostwire not accessible after 30 seconds"
            kubectl logs -n "${NAMESPACE}" -l app.kubernetes.io/name=ghostwire --tail=50
            kill "$PORT_FORWARD_PID" 2>/dev/null || true
            exit 1
        fi
        sleep 1
    done

    log "Creating test directories..."
    mkdir -p "${SCREENSHOT_DIR}"

    log "Running Playwright test..."
    docker run --rm \
        --network host \
        -v "${SCREENSHOT_DIR}:/screenshots" \
        -e GHOSTWIRE_URL="${GHOSTWIRE_URL}" \
        mcr.microsoft.com/playwright:v1.56.1-noble \
        /bin/bash -c '
            cd /tmp
            cat > test.js << "EOF"
const { chromium } = require("playwright");

(async () => {
    const browser = await chromium.launch({
        headless: true,
        args: ["--no-sandbox", "--disable-setuid-sandbox"]
    });
    
    const context = await browser.newContext({
        ignoreHTTPSErrors: true,
        viewport: { width: 1920, height: 1080 }
    });
    
    const page = await context.newPage();
    
    console.log("Navigating to:", process.env.GHOSTWIRE_URL);
    await page.goto(process.env.GHOSTWIRE_URL + "/?keyboard=1", {
        waitUntil: "networkidle",
        timeout: 30000
    });
    
    console.log("Waiting for page to load...");
    await page.waitForTimeout(5000);
    
    console.log("Taking screenshot...");
    await page.screenshot({
        path: "/screenshots/ghostwire-vnc.png",
        fullPage: true
    });
    
    console.log("✅ Test completed successfully");
    console.log("Title:", await page.title());
    
    await browser.close();
})().catch(err => {
    console.error("❌ Test failed:", err);
    process.exit(1);
});
EOF
            npm install playwright
            node test.js
        '

    log "✅ Test completed successfully"
    log "Screenshot saved to: ${SCREENSHOT_DIR}/ghostwire-vnc.png"
    
    # Show pod logs
    log "Ghostwire pod logs:"
    kubectl logs -n "${NAMESPACE}" -l app.kubernetes.io/name=ghostwire --tail=20
}

main "$@"
