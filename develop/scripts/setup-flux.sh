#!/usr/bin/env bash
set -e

KEY_DIR="${HOME}/.ssh/flux-ghostwire"
KEY_FILE="${KEY_DIR}/identity-dev"

# Prerequisites
command -v gh &> /dev/null || { echo "❌ gh CLI required"; exit 1; }
gh auth status &> /dev/null || { echo "❌ Run: gh auth login"; exit 1; }
kubectl config use-context k3d-ghostwire 2>/dev/null || true

# SSH key
if [[ ! -f "${KEY_FILE}" ]]; then
  mkdir -p "${KEY_DIR}"
  ssh-keygen -t ed25519 -C "flux-k3d-ghostwire" -f "${KEY_FILE}" -N ""
  chmod 600 "${KEY_FILE}"
fi

# GitHub deploy key
KEY_ID=$(gh api repos/drengskapur/ghostwire/keys --jq '.[] | select(.title == "flux-k3d-ghostwire") | .id' 2>/dev/null || echo "")
if [[ -z "${KEY_ID}" ]]; then
  gh api -X POST repos/drengskapur/ghostwire/keys \
    -f "title=flux-k3d-ghostwire" \
    -f "key=$(cat ${KEY_FILE}.pub)" \
    -F "read_only=true" > /dev/null
fi

# K8s secrets
kubectl create namespace flux-system --dry-run=client -o yaml | kubectl apply -f -
kubectl delete secret flux-system -n flux-system &> /dev/null || true
kubectl create secret generic flux-system -n flux-system \
  --from-file=identity="${KEY_FILE}" \
  --from-file=identity.pub="${KEY_FILE}.pub" \
  --from-literal=known_hosts="$(ssh-keyscan github.com 2>/dev/null)"

if [[ -n "${DOCKER_USERNAME:-}" && -n "${DOCKER_PASSWORD:-}" ]]; then
  kubectl delete secret github-credentials -n flux-system &> /dev/null || true
  kubectl create secret docker-registry github-credentials -n flux-system \
    --docker-server=ghcr.io \
    --docker-username="${DOCKER_USERNAME}" \
    --docker-password="${DOCKER_PASSWORD}"
fi

# Install Flux
flux check &> /dev/null || flux install

# Wait for CRDs to be ready
echo "⏳ Waiting for Flux CRDs to be ready..."
kubectl wait --for condition=established --timeout=60s \
  crd/gitrepositories.source.toolkit.fluxcd.io \
  crd/kustomizations.kustomize.toolkit.fluxcd.io \
  crd/helmrepositories.source.toolkit.fluxcd.io \
  crd/helmreleases.helm.toolkit.fluxcd.io

# Apply configurations
kubectl apply -f flux-system/
kubectl apply -f ghcr-helmrepo.yaml
kubectl apply -f helmrelease.yaml

echo "✅ FluxCD GitOps setup complete!"
echo ""
flux get sources git && echo "" && flux get kustomizations && echo "" && flux get helmreleases -A
