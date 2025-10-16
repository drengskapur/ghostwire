# Chart Versioning Policy

## Immutability

**Chart versions are immutable and cannot be overwritten once published.**

This ensures:
- **Reproducibility**: Deployments using version X always get the same chart
- **Trust**: Version tags can be trusted as permanent references
- **Safety**: Prevents accidental overwrites that could break existing deployments
- **Compliance**: Auditability for production environments

## Protection Mechanisms

### 1. Pre-Publish Check
The GitHub Actions workflow checks if a version exists before publishing:

```yaml
- name: Check if version already exists
  run: |
    if helm pull oci://ghcr.io/drengskapur/chart/ghostwire --version ${VERSION}; then
      echo "❌ ERROR: Version already exists!"
      exit 1
    fi
```

If the version exists, the workflow fails with an error.

### 2. Semantic Versioning
Versions follow [SemVer](https://semver.org/): `MAJOR.MINOR.PATCH`

The workflow automatically bumps versions based on [Conventional Commits](https://www.conventionalcommits.org/):

| Commit Prefix | Version Bump | Example |
|---------------|--------------|---------|
| `feat:` or `feature:` | **Minor** (0.X.0) | New feature |
| `fix:` or `bugfix:` | **Patch** (0.0.X) | Bug fix |
| `feat!:` or `BREAKING CHANGE` | **Major** (X.0.0) | Breaking change |
| `chore:`, `docs:`, etc. | **None** | No version change |

### 3. Manual Version Bumps
If you need to manually set a version:

```bash
# Edit Chart.yaml
version: 1.4.0

# Commit with a message that won't trigger auto-bump
git commit -m "chore: bump chart version to 1.4.0"
```

The `chore:` prefix prevents the workflow from attempting another bump.

## Publishing Process

1. **Commit changes** with a conventional commit message
2. **Push to main** branch
3. **Workflow runs**:
   - Lints and tests the chart
   - Calculates next version from commit message
   - Checks if version already exists
   - If new version: packages, tags, and publishes
   - Creates GitHub release with changelog

## Version History

The workflow maintains:
- **Git tags**: `v1.3.0`, `v1.2.0`, etc.
- **OCI tags**: Published to `ghcr.io/drengskapur/chart/ghostwire`

## Rollback

To roll back a deployment, reference an older version:

```yaml
# HelmRelease
spec:
  chart:
    spec:
      version: '1.2.0'  # Pin to specific version
```

Never delete published versions - they may be in use by other deployments.

## Best Practices

1. ✅ **Use conventional commits** for automatic versioning
2. ✅ **Test locally** before pushing to main
3. ✅ **Review Chart.yaml** to ensure version makes sense
4. ✅ **Pin versions** in production HelmReleases
5. ❌ **Never force-push** to main branch
6. ❌ **Never manually delete** published versions from GHCR

## Troubleshooting

### "Version already exists" error

This means you're trying to publish a version that's already in the registry.

**Solutions**:
1. Check `Chart.yaml` - did you forget to bump the version?
2. Use a different commit message that triggers a version bump
3. Manually bump the version in `Chart.yaml`

### Version didn't auto-bump

The workflow only bumps versions for `feat:`, `fix:`, or breaking changes.

If you used `chore:`, `docs:`, etc., manually bump the version in `Chart.yaml`.

## Examples

```bash
# Feature commit - bumps minor version (1.2.0 → 1.3.0)
git commit -m "feat: enable data retention by default"

# Fix commit - bumps patch version (1.2.0 → 1.2.1)
git commit -m "fix: correct memory limit calculation"

# Breaking change - bumps major version (1.2.0 → 2.0.0)
git commit -m "feat!: change default resource limits

BREAKING CHANGE: Default memory limit changed from 4Gi to 6Gi"

# No version bump - use for docs, chores
git commit -m "chore: update README"
git commit -m "docs: add versioning policy"
```
