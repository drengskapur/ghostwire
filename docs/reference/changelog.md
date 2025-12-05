# Changelog

All notable changes to the Ghostwire Helm chart.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

For the full changelog, see [CHANGELOG.md](https://github.com/drengskapur/ghostwire/blob/main/CHANGELOG.md) in the repository root.

## Summary of Changes

This page provides an overview of changes. For detailed commit history and release notes, see the [GitHub Releases](https://github.com/drengskapur/ghostwire/releases) page.

## Upgrade Notes

When upgrading between versions, review:

1. **Breaking changes** — Look for major version bumps or explicit breaking change notes
2. **Value changes** — Compare your custom values against new defaults
3. **Deprecations** — Update deprecated values before they're removed

## Version History

Version history is maintained in the repository's CHANGELOG.md file, generated using [git-cliff](https://git-cliff.org/) with conventional commits.

### Recent Releases

See [GitHub Releases](https://github.com/drengskapur/ghostwire/releases) for:
- Release notes
- Assets (chart packages)
- Commit history since last release

### Checking Installed Version

```bash
helm list -n ghostwire
```

### Comparing Versions

```bash
# Show available versions
helm search repo ghostwire --versions

# Compare values between versions
helm show values ghostwire/ghostwire --version 1.0.0 > v1.yaml
helm show values ghostwire/ghostwire --version 2.0.0 > v2.yaml
diff v1.yaml v2.yaml
```
