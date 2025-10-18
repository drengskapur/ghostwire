# Fuzzing Strategy

## Overview

This document describes the fuzzing and property-based testing strategy for the Ghostwire Helm chart project.

## Context: Fuzzing for Infrastructure-as-Code

Traditional fuzzing tools like [OSS-Fuzz](https://github.com/google/oss-fuzz) are designed for compiled languages and runtime code (C, C++, Go, Rust, Python, etc.). Ghostwire is primarily a **declarative Infrastructure-as-Code (IaC)** project consisting of:

- **Helm templates** (Go templates generating YAML)
- **Shell scripts** (Bash automation)
- **YAML configuration** (values.yaml, workflow files)

For this project type, we implement **adapted fuzzing strategies** appropriate to the codebase composition.

## Our Fuzzing Approach

### 1. Helm Template Property-Based Testing

**What it does:**
- Generates random valid `values.yaml` configurations
- Renders Helm templates with these configurations
- Validates that templates render without errors
- Checks that generated manifests are valid Kubernetes YAML

**Implementation:** `scripts/helm-fuzz.sh`

**Coverage:**
- Random replica counts (1-5)
- Random resource limits and requests
- Random boolean flags (persistence, ingress, autoscaling)
- Random ports and UID/GID values
- Random service types (ClusterIP, NodePort)
- Random security context configurations

**Execution:**
```bash
# Run locally with default iterations (100)
./scripts/helm-fuzz.sh

# Run with custom iteration count
FUZZ_ITERATIONS=1000 ./scripts/helm-fuzz.sh
```

**Automated testing:**
- GitHub Actions workflow runs weekly (Sundays at 2:00 UTC)
- Manual trigger available via workflow_dispatch
- See `.github/workflows/fuzzing.yml`

### 2. Static Analysis (Shell Scripts)

**What it does:**
- Deep static analysis of all shell scripts
- Checks for common vulnerabilities and anti-patterns
- Uses ShellCheck with `severity: style` for comprehensive coverage

**Coverage:**
- `scripts/generate-schema.sh`
- `scripts/trivy-scan.sh`
- `scripts/generate-changelog.sh`
- `scripts/helm-fuzz.sh`
- Helm template helpers (limited bash-like syntax)

### 3. Schema Validation Fuzzing

**What it does:**
- Helm JSON Schema validation in `values.schema.json`
- Automatically rejects invalid configurations at install-time
- Provides immediate feedback on malformed values

**How it helps:**
- Prevents invalid configurations from being deployed
- Catches type mismatches, missing required fields, invalid enums
- Acts as a "fuzz test gatekeeper" during production use

## Why Not OSS-Fuzz?

OSS-Fuzz is excellent for finding memory corruption bugs, crashes, and undefined behavior in **compiled runtime code**. However:

1. **No runtime code:** Helm charts are declarative templates, not executable programs
2. **Validation happens at render-time:** Helm validates during `helm template` or `helm install`
3. **Different threat model:** IaC vulnerabilities are typically:
   - Misconfigurations (wrong permissions, exposed secrets)
   - Template injection (user-controlled values rendered unsafely)
   - Invalid YAML generation

These are better caught by:
- Property-based testing (our `helm-fuzz.sh`)
- Static analysis (ShellCheck, Trivy, yamllint)
- Schema validation (`values.schema.json`)
- Security policy enforcement (OPA, Kyverno)

## Future Enhancements

### Potential Additions

1. **Template Injection Testing**
   - Test for unsafe rendering of user-provided values
   - Validate quote escaping in templates
   - Check for YAML injection vectors

2. **Kubernetes Manifest Validation**
   - Post-render validation with `kubectl --dry-run=server`
   - Admission controller simulation
   - Policy engine testing (OPA/Gatekeeper)

3. **Integration with Kubeconform**
   - Validate generated manifests against Kubernetes schemas
   - Test compatibility across multiple K8s versions

4. **Mutation Testing**
   - Deliberately introduce errors in templates
   - Verify that tests catch the errors

### Considered but Deferred

- **OSS-Fuzz integration:** Not applicable for IaC/Helm projects
- **AFL/libFuzzer:** Require compiled binaries, not suitable for templates
- **Go fuzzing:** Would require rewriting templates as Go code (impractical)

## Measuring Effectiveness

### Success Metrics

- **Coverage:** Percentage of template branches exercised
- **Error detection:** Number of rendering errors caught
- **Regression prevention:** Tests that catch breaking changes

### Current Status

| Metric | Value |
|--------|-------|
| Fuzzing iterations | 100 per run |
| Template coverage | ~80% (estimated) |
| Execution frequency | Weekly + on-demand |
| Shell script analysis | 100% of scripts |

## Contributing

To improve fuzzing coverage:

1. Add new value combinations to `helm-fuzz.sh`
2. Increase iteration count for deeper testing
3. Add validation checks for specific Kubernetes resources
4. Propose additional fuzzing strategies via GitHub Issues

## References

- [OSS-Fuzz](https://github.com/google/oss-fuzz) - Not applicable for Helm
- [Helm Unit Testing](https://github.com/helm-unittest/helm-unittest) - Complements fuzzing
- [Property-Based Testing](https://en.wikipedia.org/wiki/Property-based_testing) - Our approach
- [ShellCheck](https://www.shellcheck.net/) - Static analysis for scripts

---

**Bottom Line:** While traditional fuzzing isn't applicable to Helm charts, we implement adapted strategies (property-based testing, static analysis, schema validation) that provide equivalent risk reduction for this project type.
