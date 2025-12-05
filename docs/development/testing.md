# Testing

Ghostwire uses multiple testing approaches to ensure chart quality and reliability.

## Chart Linting

Basic syntax and best practice validation:

```bash
helm lint ./chart
```

This checks for:
- Template syntax errors
- Missing required values
- Chart metadata issues

## Template Rendering

Validate rendered manifests without deploying:

```bash
# Render templates
helm template ghostwire ./chart

# Check against Kubernetes API
helm template ghostwire ./chart | kubectl apply --dry-run=client -f -

# Render with custom values
helm template ghostwire ./chart -f custom-values.yaml
```

## Schema Validation

The chart includes `values.schema.json` for validating user-provided values:

```bash
# Lint with value validation
helm lint ./chart -f values-production.yaml
```

Schema validation catches:
- Invalid types (string where number expected)
- Unknown value keys
- Missing required values
- Out-of-range values

## Helm Tests

The chart includes Helm tests that run after installation:

```bash
# Install and run tests
helm install ghostwire ./chart -n ghostwire --create-namespace
helm test ghostwire -n ghostwire
```

Tests validate:
- VNC port is accessible
- Pod is running and ready
- PVC is bound

### Test Pod

```yaml
# chart/templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "ghostwire.fullname" . }}-test"
  annotations:
    "helm.sh/hook": test
spec:
  containers:
    - name: curl
      image: curlimages/curl
      command: ['curl', '-s', '-o', '/dev/null', '-w', '%{http_code}', 'http://{{ include "ghostwire.fullname" . }}:6901']
  restartPolicy: Never
```

## Integration Testing

Full end-to-end testing on a real cluster:

```bash
# Create test cluster
k3d cluster create ghostwire-test

# Install chart
helm install ghostwire ./chart -n ghostwire --create-namespace

# Wait for ready
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=ghostwire -n ghostwire --timeout=300s

# Run tests
helm test ghostwire -n ghostwire

# Cleanup
k3d cluster delete ghostwire-test
```

## CI Pipeline

GitHub Actions runs tests on every pull request:

```yaml
# .github/workflows/helm-lint-test.yml
name: Lint and Test

on:
  pull_request:
    paths:
      - 'chart/**'

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: azure/setup-helm@v3
      - run: helm lint ./chart

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: azure/setup-helm@v3
      - name: Create k3d cluster
        run: |
          curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
          k3d cluster create test
      - name: Install and test
        run: |
          helm install ghostwire ./chart -n ghostwire --create-namespace
          kubectl wait --for=condition=ready pod \
            -l app.kubernetes.io/name=ghostwire -n ghostwire --timeout=300s
          helm test ghostwire -n ghostwire
```

## Testing Upgrades

Verify upgrades work correctly:

```bash
# Install previous version
helm install ghostwire ./chart --version 1.0.0 -n ghostwire --create-namespace

# Upgrade to new version
helm upgrade ghostwire ./chart -n ghostwire

# Verify pod restarts successfully
kubectl rollout status statefulset/ghostwire -n ghostwire
```

## Testing Rollback

```bash
# Upgrade to a broken version
helm upgrade ghostwire ./chart --set image.tag=nonexistent -n ghostwire

# Rollback
helm rollback ghostwire -n ghostwire

# Verify recovery
kubectl get pods -n ghostwire
```

## Manual Testing Checklist

For changes that affect user experience:

- [ ] Pod starts successfully
- [ ] VNC connection works
- [ ] Signal Desktop loads
- [ ] Can link with phone (if testing fresh install)
- [ ] Data persists across pod restart
- [ ] Logs show no errors
- [ ] Resource usage is within limits

## Security Testing

### Container Security

```bash
# Scan image for vulnerabilities
trivy image kasmweb/signal:1.18.0-rolling-daily

# Check pod security context
kubectl get pod ghostwire-0 -n ghostwire -o jsonpath='{.spec.securityContext}'
```

### RBAC Verification

```bash
# List RBAC resources
kubectl get rolebinding,clusterrolebinding -n ghostwire

# Verify minimal permissions
kubectl auth can-i --list --as=system:serviceaccount:ghostwire:ghostwire -n ghostwire
```
