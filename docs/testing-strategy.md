# Testing Strategy

This document describes the testing approach for the Ghostwire Helm chart.

## Overview

The Ghostwire project uses a multi-layered testing strategy to ensure quality, security, and reliability:

1. **Static Analysis** - Linting and validation before deployment
2. **Template Testing** - Helm template rendering verification
3. **Security Scanning** - Vulnerability and misconfiguration detection
4. **Integration Testing** - Deployment verification in Kubernetes clusters

---

## Test Execution

### Local Development

Run all tests locally using Task:

```bash
# Run all tests
task test

# Individual test types
helm lint chart/
helm template test chart/ --debug
```

### CI/CD Pipeline

All tests run automatically on:
- **Push to main** - Full test suite
- **Pull requests** - Full test suite + additional security checks
- **Tag creation** - Full suite + release validation

See `.github/workflows/helm-release.yml` for CI configuration.

---

## Test Categories

### 1. Static Analysis

**Purpose:** Catch errors before rendering or deployment

**Tools:**
- `helm lint` - Chart structure and syntax validation
- `yamllint` - YAML formatting and best practices
- Helm schema validation (values.schema.json)

**Coverage:**
- Chart.yaml metadata validation
- Template syntax checking
- Values.yaml schema compliance
- YAML formatting standards

**Pass Criteria:**
- Zero linting errors
- Zero schema validation errors
- All templates parseable

**Example:**
```bash
cd chart/
helm lint .
```

### 2. Template Rendering Tests

**Purpose:** Verify templates render correctly with various configurations

**Tools:**
- `helm template` - Dry-run template rendering
- Custom test scripts - Configuration variation testing

**Coverage:**
- Default values rendering
- Common configuration variations:
  - Ingress enabled/disabled
  - Persistence enabled/disabled
  - Resource limits variations
  - Security context configurations
- Edge cases (empty values, maximum values)

**Pass Criteria:**
- All templates render without errors
- Generated manifests are valid Kubernetes resources
- No template logic errors
- Conditional blocks work as expected

**Example:**
```bash
# Test default rendering
helm template test chart/

# Test with ingress enabled
helm template test chart/ --set ingress.enabled=true

# Test with custom values
helm template test chart/ -f tests/test-values.yaml
```

### 3. Fuzzing and Property-Based Testing

**Purpose:** Discover edge cases and rendering failures through randomized testing

**Tools:**
- Custom Helm fuzzing script (`scripts/helm-fuzz.sh`)
- Property-based test generation
- ShellCheck deep analysis

**Coverage:**
- Random valid `values.yaml` configurations
- Edge cases in template rendering
- Boundary value testing (min/max replicas, ports, UIDs)
- Random boolean flag combinations
- Resource limit permutations

**Pass Criteria:**
- All fuzzed configurations render without errors
- Generated manifests are valid YAML
- No template panics or crashes
- Success rate: 100% of iterations

**Example:**
```bash
# Run fuzzing with default iterations (100)
./scripts/helm-fuzz.sh

# Run with more iterations for deeper testing
FUZZ_ITERATIONS=1000 ./scripts/helm-fuzz.sh
```

**Automated Execution:**
- GitHub Actions workflow runs weekly (`.github/workflows/fuzzing.yml`)
- Manual trigger available for on-demand testing

**Why This Approach:**

Traditional fuzzing (OSS-Fuzz, AFL) targets compiled runtime code. Helm charts are declarative templates, so we use **property-based testing** instead:
- Generate random valid configurations
- Verify templates always render successfully
- Catch edge cases that unit tests miss

See [Fuzzing Strategy](fuzzing-strategy.md) for detailed explanation.

### 4. Kubernetes Schema Validation

**Purpose:** Ensure generated manifests are valid Kubernetes resources

**Tools:**
- `kubectl apply --dry-run=client` - Client-side validation
- `kubectl apply --dry-run=server` - Server-side validation (requires cluster)

**Coverage:**
- All generated resources match Kubernetes API schemas
- API version compatibility
- Required field validation
- Type checking

**Pass Criteria:**
- Client-side dry-run succeeds
- No schema validation errors
- Resources compatible with target Kubernetes versions (1.25+)

**Example:**
```bash
helm template test chart/ | kubectl apply --dry-run=client -f -
```

### 5. Security Scanning

**Purpose:** Identify vulnerabilities, misconfigurations, and secrets

**Tools:**
- **Trivy** - Vulnerability and IaC scanning
- **TruffleHog** - Secret detection in git history
- **Gitleaks** - Credential leak detection
- **Dependabot** - Dependency vulnerability alerts
- **Renovate** - Automated dependency updates

**Coverage:**
- Container image vulnerabilities
- Helm chart misconfigurations
- Hardcoded secrets
- Dependency vulnerabilities
- Infrastructure-as-Code best practices

**Severity Thresholds:**
- **Critical/High** - Must fix before release
- **Medium** - Fix in next patch release
- **Low** - Fix in next minor release

**Pass Criteria:**
- Zero critical/high vulnerabilities in latest release
- No secrets in repository history
- All dependencies up-to-date or patched

**Example:**
```bash
# Run security scans
task scan

# Scan Helm chart
trivy config --severity HIGH,CRITICAL chart/

# Scan container images
trivy image kasmweb/signal:1.18.0-rolling-daily
```

### 5. Integration Testing

**Purpose:** Verify chart deploys successfully in real Kubernetes clusters

**Tools:**
- Local Kubernetes (k3d, kind, minikube)
- `helm install` - Chart installation
- `helm test` - Built-in Helm tests (future)
- Manual verification

**Coverage:**
- Installation succeeds
- All pods reach Running state
- Services are created correctly
- Ingress configuration works (if enabled)
- Persistence works (StatefulSet)
- Application functionality (manual)

**Test Environments:**
- k3d (local development)
- kind (CI/CD)
- Production-like cluster (staging)

**Pass Criteria:**
- Chart installs without errors
- All resources created successfully
- Pods become healthy within 5 minutes
- Application accessible via port-forward or ingress
- Upgrade/rollback work correctly

**Example:**
```bash
# Create test cluster
k3d cluster create ghostwire-test

# Install chart
helm install test ./chart -n test --create-namespace

# Verify installation
kubectl get pods -n test
kubectl port-forward -n test svc/test 6901:6901

# Test upgrade
helm upgrade test ./chart -n test --set image.tag=1.19.0

# Cleanup
helm uninstall test -n test
k3d cluster delete ghostwire-test
```

---

## Test Coverage Metrics

### Current Coverage

**Template Coverage:** ~95%
- All templates tested with default values
- Major configuration variations covered
- Edge cases identified and tested

**Integration Coverage:** Manual
- Installation tested on k3d, kind, minikube
- Production deployments monitored
- Upgrade paths tested

**Security Coverage:** 100%
- All code paths scanned by Trivy
- Repository history scanned for secrets
- Dependencies monitored continuously

### Coverage Goals

- **Template Coverage:** 100% - Cover all conditional blocks
- **Integration Coverage:** Automated tests for common scenarios
- **Security Coverage:** Maintain 100% with automated scanning

---

## Test Automation

### Pre-commit Hooks

Install pre-commit hooks to run tests before commits:

```bash
# Future: Add pre-commit configuration
# .pre-commit-config.yaml with:
# - helm lint
# - yaml lint
# - secret scanning
```

### CI/CD Gates

**Required Checks:**
- ✅ Helm lint
- ✅ Template rendering
- ✅ Trivy security scan
- ✅ Secret scanning

**Blocking Conditions:**
- Linting errors
- Template rendering failures
- Critical/high vulnerabilities
- Secrets detected

### Automated Testing Schedule

- **On PR:** All checks run
- **On merge to main:** All checks + extended security scans
- **Nightly:** Full security scan with latest Trivy DB
- **Weekly:** Dependency update checks (Renovate)

---

## Adding New Tests

### For New Features

1. Add template tests for new configurations
2. Document new values in values.schema.json
3. Add integration test examples to documentation
4. Update this testing strategy document

### For Bug Fixes

1. Add test case that reproduces the bug
2. Verify test fails before fix
3. Verify test passes after fix
4. Add regression test to prevent recurrence

---

## Test Maintenance

### Regular Tasks

- **Weekly:** Review Trivy scan results
- **Monthly:** Update test dependencies
- **Quarterly:** Review and update test coverage
- **Annually:** Validate tests against new Kubernetes versions

### Test Infrastructure

- Keep test clusters updated
- Monitor CI/CD execution times
- Optimize slow tests
- Remove obsolete tests

---

## Known Limitations

1. **No Unit Tests:** Helm charts are declarative - limited unit test value
2. **Manual Application Testing:** Signal Desktop functionality requires manual QA
3. **Limited Upgrade Testing:** Automated upgrade path testing not yet implemented
4. **Browser Compatibility:** VNC client testing is manual

---

## Resources

- [Helm Testing Guide](https://helm.sh/docs/topics/chart_tests/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Kubernetes API Reference](https://kubernetes.io/docs/reference/)

---

## Future Enhancements

- [ ] Add `helm test` hooks for automated post-install validation
- [ ] Implement automated upgrade path testing
- [ ] Add performance benchmarking tests
- [ ] Create test matrix for Kubernetes version compatibility
- [ ] Add chaos engineering tests for resilience validation
