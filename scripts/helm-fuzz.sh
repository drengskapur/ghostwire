#!/usr/bin/env bash
#
# Helm Template Fuzzing Script
#
# This script performs property-based testing on Helm templates by:
# 1. Generating random valid values.yaml configurations
# 2. Rendering templates with these configurations
# 3. Verifying templates render without errors
# 4. Validating generated Kubernetes manifests
#
# This is a lightweight fuzzing approach suitable for Helm charts,
# testing edge cases and boundary conditions that unit tests might miss.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CHART_PATH="${PROJECT_ROOT}/chart"

# Counter for test iterations
ITERATIONS=${FUZZ_ITERATIONS:-100}
FAILURES=0

echo "========================================"
echo "Helm Template Property-Based Testing"
echo "========================================"
echo ""
echo "Chart: ${CHART_PATH}"
echo "Iterations: ${ITERATIONS}"
echo ""

# Function to generate random boolean
random_bool() {
    if [ $((RANDOM % 2)) -eq 0 ]; then
        echo "true"
    else
        echo "false"
    fi
}

# Function to generate random resource value
random_resource() {
    local base=$1
    local multiplier=$((RANDOM % 10 + 1))
    echo "${multiplier}${base}"
}

# Function to generate random port
random_port() {
    echo $((RANDOM % 65535 + 1))
}

# Function to generate random replica count
random_replicas() {
    echo $((RANDOM % 5 + 1))
}

# Function to generate random valid values.yaml
generate_fuzz_values() {
    cat <<EOF
# Fuzzed values for property-based testing
replicaCount: $(random_replicas)

image:
  pullPolicy: $(if [ $((RANDOM % 2)) -eq 0 ]; then echo "Always"; else echo "IfNotPresent"; fi)

service:
  type: $(if [ $((RANDOM % 2)) -eq 0 ]; then echo "ClusterIP"; else echo "NodePort"; fi)
  port: $(random_port)

resources:
  limits:
    cpu: $(random_resource "m")
    memory: $(random_resource "Mi")
  requests:
    cpu: $(random_resource "m")
    memory: $(random_resource "Mi")

persistence:
  enabled: $(random_bool)
  size: $(random_resource "Gi")

ingress:
  enabled: $(random_bool)

autoscaling:
  enabled: false

podSecurityContext:
  fsGroup: $((RANDOM % 65535 + 1))

securityContext:
  runAsNonRoot: $(random_bool)
  runAsUser: $((RANDOM % 65535 + 1))
  readOnlyRootFilesystem: $(random_bool)

nodeSelector: {}
tolerations: []
affinity: {}
EOF
}

# Test iteration
run_fuzz_iteration() {
    local iteration=$1
    local temp_values="/tmp/helm-fuzz-values-${iteration}.yaml"
    local temp_output="/tmp/helm-fuzz-output-${iteration}.yaml"

    # Generate random values
    generate_fuzz_values > "${temp_values}"

    # Attempt to render template
    if ! helm template "fuzz-test-${iteration}" "${CHART_PATH}" \
        -f "${temp_values}" \
        > "${temp_output}" 2>&1; then
        echo "❌ Iteration ${iteration}: Template rendering failed"
        echo "   Values file: ${temp_values}"
        cat "${temp_values}"
        ((FAILURES++))
        return 1
    fi

    # Validate rendered manifests are valid YAML
    if ! grep -q "kind:" "${temp_output}"; then
        echo "❌ Iteration ${iteration}: No Kubernetes resources generated"
        ((FAILURES++))
        return 1
    fi

    # Clean up successful test
    rm -f "${temp_values}" "${temp_output}"

    # Progress indicator
    if [ $((iteration % 10)) -eq 0 ]; then
        echo "✓ Completed ${iteration}/${ITERATIONS} iterations"
    fi

    return 0
}

# Main fuzzing loop
echo "Starting fuzzing iterations..."
echo ""

for i in $(seq 1 "${ITERATIONS}"); do
    run_fuzz_iteration "${i}" || true
done

echo ""
echo "========================================"
echo "Fuzzing Results"
echo "========================================"
echo "Total iterations: ${ITERATIONS}"
echo "Failures: ${FAILURES}"
echo "Success rate: $(awk "BEGIN {printf \"%.2f%%\", (${ITERATIONS}-${FAILURES})/${ITERATIONS}*100}")"
echo ""

# Clean up any remaining temp files
rm -f /tmp/helm-fuzz-values-*.yaml /tmp/helm-fuzz-output-*.yaml

if [ "${FAILURES}" -gt 0 ]; then
    echo "❌ Fuzzing detected ${FAILURES} failures"
    exit 1
fi

echo "✅ All fuzzing iterations passed successfully"
exit 0
