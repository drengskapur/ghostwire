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

### 1. Native Go fuzzing of chart rendering

The chart's external input is the values overlay passed to Helm. `fuzz/render_test.go` defines `FuzzRender`, a Go 1.18+ fuzz target. Each iteration writes the fuzz bytes to a values file and runs `helm template`. Values Helm rejects are discarded. Values Helm accepts must render as YAML, and a renderer panic fails the test.

Run it locally:

```bash
go test -C fuzz -fuzz=FuzzRender -fuzztime=30s
```

CI runs the same target for 30 seconds on every pull request and push to `main` (job `fuzz` in `.github/workflows/fuzzing.yml`).

ClusterFuzzLite can build the same target. `.clusterfuzzlite/Dockerfile` pins the OSS-Fuzz Go builder by digest, installs a hash-pinned Helm, and `.clusterfuzzlite/build.sh` compiles `FuzzRender`. OpenSSF Scorecard treats `.clusterfuzzlite/Dockerfile` as a fuzzing integration.

### 2. Helm Template Property-Based Testing

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

### 3. Static Analysis (Shell Scripts)

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

### 4. Schema Validation Fuzzing

**What it does:**
- Helm JSON Schema validation in `values.schema.json`
- Automatically rejects invalid configurations at install-time
- Provides immediate feedback on malformed values

**How it helps:**
- Prevents invalid configurations from being deployed
- Catches type mismatches, missing required fields, invalid enums
- Acts as a "fuzz test gatekeeper" during production use

## Why the fuzzer calls Helm

OSS-Fuzz looks for memory corruption in compiled programs. This repository's input is a Helm values overlay. `FuzzRender` treats `helm template` as that parser: bad values are discarded, accepted values must render as YAML, and a panic fails the test. ClusterFuzzLite builds that target. The project is not registered with OSS-Fuzz.

The same input is also exercised by:

- Property-based testing (`scripts/helm-fuzz.sh`)
- Static analysis (ShellCheck, Trivy, yamllint)
- Schema validation (`values.schema.json`)

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

- **OSS-Fuzz project registration:** Not set up. ClusterFuzzLite in this repository builds the same Go fuzz target.
- **AFL:** The chart is not a C/C++ binary. The Go fuzz target calls Helm, which is the program that parses values.

## Measuring Effectiveness

### Success Metrics

- **Coverage:** Percentage of template branches exercised
- **Error detection:** Number of rendering errors caught
- **Regression prevention:** Tests that catch breaking changes

### Current Status

| Metric | Value |
|--------|-------|
| Go fuzz target | `FuzzRender`, 30 seconds on every pull request and push |
| Property-test iterations | 100 per run of `scripts/helm-fuzz.sh` |
| Execution frequency | Pull requests, pushes to `main`, weekly, and on demand |
| Shell script analysis | Scripts under `scripts/` |

## Contributing

To improve fuzzing coverage:

1. Add new value combinations to `helm-fuzz.sh`
2. Increase iteration count for deeper testing
3. Add validation checks for specific Kubernetes resources
4. Propose additional fuzzing strategies via GitHub Issues

## References

- [ClusterFuzzLite](https://google.github.io/clusterfuzzlite/) - Builds `FuzzRender` from `.clusterfuzzlite/`
- [OSS-Fuzz](https://github.com/google/oss-fuzz) - Not registered; the in-repo target is the one CI runs
- [Helm Unit Testing](https://github.com/helm-unittest/helm-unittest) - Complements fuzzing
- [Property-Based Testing](https://en.wikipedia.org/wiki/Property-based_testing) - Our approach
- [ShellCheck](https://www.shellcheck.net/) - Static analysis for scripts

---

**Bottom Line:** `FuzzRender` fuzzes Helm's rendering of this chart, in CI and via ClusterFuzzLite. Property tests, static analysis, and schema validation cover the same input from the other side.
