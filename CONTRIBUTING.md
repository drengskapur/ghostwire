# Contributing to Ghostwire

Thank you for your interest in contributing to Ghostwire! This document provides guidelines and instructions for contributing.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing](#testing)
- [Documentation](#documentation)

---

## Code of Conduct

Please read and abide by our Code of Conduct: [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md)

---

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/ghostwire.git
   cd ghostwire
   ```
3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/drengskapur/ghostwire.git
   ```

---

## Development Setup

### Prerequisites

- [Helm](https://helm.sh/docs/intro/install/) v3.x
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Task](https://taskfile.dev/) (optional, for automation)
- Kubernetes cluster (local or remote):
  - [k3d](https://k3d.io/) (recommended for local development)
  - [kind](https://kind.sigs.k8s.io/)
  - [minikube](https://minikube.sigs.k8s.io/)
  - Or any remote cluster

### Local Development

```bash
# Test the Helm chart
task test

# Or manually:
helm lint chart/
helm template test chart/ > /dev/null
```

### Test in Kubernetes

```bash
# Install in test namespace
helm install ghostwire-test ./chart -n ghostwire-test --create-namespace

# Port-forward to test
kubectl port-forward -n ghostwire-test svc/ghostwire-test 6901:6901

# Open browser
open http://localhost:6901?keyboard=1

# Clean up
helm uninstall ghostwire-test -n ghostwire-test
kubectl delete namespace ghostwire-test
```

---

## Making Changes

### Branching Strategy

- `main` - Stable, production-ready code
- `develop` - Integration branch (if used)
- `feature/your-feature` - Feature branches
- `fix/bug-description` - Bug fix branches

```bash
# Create feature branch from main
git checkout main
git pull upstream main
git checkout -b feature/your-feature
```

### Types of Contributions

**Helm Chart Improvements:**
- New chart features or configuration options
- Enhanced templates
- Improved defaults or documentation
- Security hardening

**Documentation:**
- Fixing typos or improving clarity
- Adding examples or tutorials
- Architecture documentation
- Integration guides

**Bug Fixes:**
- Fixing chart rendering issues
- Correcting template logic
- Resolving deployment problems

**CI/CD:**
- Workflow improvements
- Automated testing enhancements
- Release automation

---

## Commit Guidelines

We use [Conventional Commits](https://www.conventionalcommits.org/) for automated versioning and changelog generation.

### Commit Message Format

```
<type>(<scope>): <short description>

<optional longer description>

<optional footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring (no functional changes)
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `ci`: CI/CD changes
- `perf`: Performance improvements

### Scopes

- `chart`: Helm chart changes
- `docs`: Documentation
- `ci`: CI/CD workflows
- `security`: Security-related changes

### Examples

```bash
# Feature addition
git commit -m "feat(chart): add support for custom ingress class"

# Bug fix
git commit -m "fix(chart): correct StatefulSet update strategy"

# Documentation
git commit -m "docs: add OAuth2-proxy integration example"

# Breaking change
git commit -m "feat(chart)!: change default service type to ClusterIP

BREAKING CHANGE: Default service.type changed from LoadBalancer to ClusterIP.
Users must explicitly set service.type=LoadBalancer or configure ingress."
```

### Breaking Changes

- Add `!` after type/scope: `feat(chart)!:`
- Include `BREAKING CHANGE:` in footer with migration notes

---

## Pull Request Process

### Before Submitting

1. **Update your branch** with latest changes:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run tests**:
   ```bash
   task test
   ```

3. **Update documentation** if needed:
   - chart/README.md for configuration changes
   - docs/ for architectural changes
   - CHANGELOG.md is auto-generated

4. **Ensure clean commit history**:
   - Squash fixup commits
   - Rebase if needed

### Submitting the PR

1. **Push to your fork**:
   ```bash
   git push origin feature/your-feature
   ```

2. **Create Pull Request** on GitHub:
   - Use a descriptive title (follows conventional commits)
   - Fill out the PR template completely
   - Link related issues (e.g., "Fixes #123")
   - Add screenshots if applicable

3. **Address review feedback**:
   - Make requested changes
   - Push additional commits
   - Request re-review when ready

### PR Requirements

- ✅ Passes all CI checks (lint, tests, security scans)
- ✅ Includes tests for new features
- ✅ Updates documentation
- ✅ Follows conventional commit format
- ✅ No merge conflicts with main
- ✅ Approved by maintainer

---

## Testing

### Helm Chart Testing

```bash
# Lint chart
helm lint chart/

# Template rendering
helm template test chart/ > /dev/null

# Validate against Kubernetes schema
helm template test chart/ | kubectl apply --dry-run=client -f -

# Run all tests
task test
```

### Manual Testing

```bash
# Install chart
helm install test ./chart -n test --create-namespace

# Test functionality
kubectl port-forward -n test svc/test 6901:6901

# Check logs
kubectl logs -n test -l app.kubernetes.io/name=ghostwire

# Clean up
helm uninstall test -n test
kubectl delete namespace test
```

### Security Testing

Security scans run automatically on PRs:
- TruffleHog (secret scanning)
- Gitleaks (credential detection)
- Trivy (vulnerability scanning)

---

## Documentation

### Chart README

Update `chart/README.md` when adding/changing:
- Configuration parameters
- Examples
- Prerequisites
- Troubleshooting steps

### Architecture Documentation

Update `docs/` for:
- Architecture changes
- New integration patterns
- Deployment strategy changes

### Code Comments

- Document complex template logic
- Explain non-obvious design decisions
- Include examples in comments

---

## Release Process

Releases are automated:
1. Merge PR to `main`
2. GitHub Actions runs:
   - Version bump (based on conventional commits)
   - CHANGELOG generation (git-cliff)
   - Chart packaging
   - OCI registry push
   - Cosign signing
   - GitHub Release creation

Manual releases (maintainers only):
```bash
# Tag release
git tag -a v0.1.0 -m "Release v0.1.0"
git push upstream v0.1.0
```

---

## Questions?

- **Documentation**: Check [chart/README.md](chart/README.md)
- **Issues**: [GitHub Issues](https://github.com/drengskapur/ghostwire/issues)
- **Discussions**: [GitHub Discussions](https://github.com/drengskapur/ghostwire/discussions)

---

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.

---

**Thank you for contributing to Ghostwire!** 🎉
