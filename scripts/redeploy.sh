#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
info() { echo -e "${BLUE}[INFO]${NC} $*"; }

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-k3s-default}"
NAMESPACE="${NAMESPACE:-ghostwire}"
RELEASE_NAME="${RELEASE_NAME:-ghostwire}"
USE_LOCAL_CHART="${USE_LOCAL_CHART:-true}"

# Track timing
START_TIME=$(date +%s)
get_elapsed() {
    echo $(($(date +%s) - START_TIME))
}

log "🚀 Starting Ghostwire redeployment with optimized memory settings..."

# Ensure k3d cluster exists
if ! k3d cluster list | grep -q "${CLUSTER_NAME}"; then
    log "Creating k3d cluster..."
    k3d cluster create "${CLUSTER_NAME}"
fi

log "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=120s || true

# Create namespace
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# Delete existing release if it exists
if helm list -n "${NAMESPACE}" | grep -q "${RELEASE_NAME}"; then
    log "🗑️  Deleting existing Helm release..."
    helm uninstall "${RELEASE_NAME}" -n "${NAMESPACE}" || true
    sleep 5
fi

# Wait for pods to terminate
log "Waiting for old pods to terminate..."
kubectl wait --for=delete pod -l app.kubernetes.io/name=ghostwire -n "${NAMESPACE}" --timeout=60s || true

# Deploy with optimized settings
log "📦 Deploying Ghostwire with optimized memory settings..."
DEPLOY_START=$(date +%s)

if [ "${USE_LOCAL_CHART}" = "true" ]; then
    log "Using local chart from ./chart"
    helm upgrade --install "${RELEASE_NAME}" ./chart \
        --namespace "${NAMESPACE}" \
        --wait --timeout=10m \
        --set resources.limits.memory=2.5Gi \
        --set resources.requests.memory=1.5Gi
else
    VERSION="${CHART_VERSION:-0.0.0-latest}"
    log "Using OCI chart version ${VERSION}"
    helm upgrade --install "${RELEASE_NAME}" oci://ghcr.io/drengskapur/charts/ghostwire \
        --version "${VERSION}" \
        --namespace "${NAMESPACE}" \
        --wait --timeout=10m \
        --set resources.limits.memory=2.5Gi \
        --set resources.requests.memory=1.5Gi
fi

DEPLOY_TIME=$(($(date +%s) - DEPLOY_START))
log "✅ Deployment completed in ${DEPLOY_TIME}s"

# Get pod name
log "Waiting for pod to be created..."
sleep 3
POD_NAME=$(kubectl get pods -n "${NAMESPACE}" -l app.kubernetes.io/name=ghostwire -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "${POD_NAME}" ]; then
    error "Pod not found!"
    kubectl get pods -n "${NAMESPACE}"
    exit 1
fi

log "Monitoring pod: ${POD_NAME}"

# Monitor startup
POD_START=$(date +%s)
READY=false
OOM_DETECTED=false
MAX_WAIT=600  # 10 minutes

log "⏱️  Monitoring startup (timeout: ${MAX_WAIT}s)..."

while [ $(($(date +%s) - POD_START)) -lt ${MAX_WAIT} ]; do
    ELAPSED=$(($(date +%s) - POD_START))
    
    # Check pod status
    PHASE=$(kubectl get pod "${POD_NAME}" -n "${NAMESPACE}" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
    READY_STATUS=$(kubectl get pod "${POD_NAME}" -n "${NAMESPACE}" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
    
    # Check for OOM
    REASON=$(kubectl get pod "${POD_NAME}" -n "${NAMESPACE}" -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}' 2>/dev/null || echo "")
    if [[ "${REASON}" == *"OOMKilled"* ]] || [[ "${REASON}" == *"OutOfMemory"* ]]; then
        OOM_DETECTED=true
        error "❌ OOM DETECTED! Reason: ${REASON}"
        break
    fi
    
    # Check logs for OOM errors
    if kubectl logs "${POD_NAME}" -n "${NAMESPACE}" --tail=100 2>/dev/null | grep -qi "out of memory\|OOM\|killed\|memory"; then
        OOM_DETECTED=true
        error "❌ OOM DETECTED in logs!"
        break
    fi
    
    # Check if ready
    if [ "${READY_STATUS}" == "True" ] && [ "${PHASE}" == "Running" ]; then
        READY=true
        log "✅ Pod is Ready! Startup time: ${ELAPSED}s"
        break
    fi
    
    # Show progress every 10 seconds
    if [ $((ELAPSED % 10)) -eq 0 ]; then
        info "  Status: ${PHASE}, Ready: ${READY_STATUS}, Elapsed: ${ELAPSED}s"
    fi
    
    sleep 2
done

# Final status check
if [ "${OOM_DETECTED}" = "true" ]; then
    error ""
    error "=========================================="
    error "OOM ERROR DETECTED!"
    error "=========================================="
    error ""
    error "Pod status:"
    kubectl get pod "${POD_NAME}" -n "${NAMESPACE}" -o wide
    error ""
    error "Pod events:"
    kubectl describe pod "${POD_NAME}" -n "${NAMESPACE}" | grep -A 20 "Events:"
    error ""
    error "Recent logs:"
    kubectl logs "${POD_NAME}" -n "${NAMESPACE}" --tail=50 || true
    error ""
    error "Memory usage:"
    kubectl top pod "${POD_NAME}" -n "${NAMESPACE}" 2>/dev/null || warn "Metrics not available"
    exit 1
fi

if [ "${READY}" = "false" ]; then
    error "Pod did not become ready within timeout"
    kubectl describe pod "${POD_NAME}" -n "${NAMESPACE}"
    exit 1
fi

# Get final metrics
log ""
log "=========================================="
log "✅ DEPLOYMENT SUCCESSFUL"
log "=========================================="
log ""
log "Startup Metrics:"
log "  - Deployment time: ${DEPLOY_TIME}s"
log "  - Pod ready time: ${ELAPSED}s"
log "  - Total time: $(get_elapsed)s"
log ""

log "Resource Usage:"
kubectl top pod "${POD_NAME}" -n "${NAMESPACE}" 2>/dev/null || warn "Metrics not available (may need metrics-server)"

log ""
log "Pod Status:"
kubectl get pod "${POD_NAME}" -n "${NAMESPACE}" -o wide

log ""
log "Resource Limits:"
kubectl get pod "${POD_NAME}" -n "${NAMESPACE}" -o jsonpath='{.spec.containers[0].resources}' | jq '.' 2>/dev/null || kubectl get pod "${POD_NAME}" -n "${NAMESPACE}" -o jsonpath='{.spec.containers[0].resources}'

log ""
log "Recent logs (last 20 lines):"
kubectl logs "${POD_NAME}" -n "${NAMESPACE}" --tail=20 || true

log ""
log "✅ Monitoring complete - No OOM errors detected!"

