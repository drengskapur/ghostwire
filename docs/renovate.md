# Renovate Bot Configuration

Ghostwire uses [Renovate](https://docs.renovatebot.com/) for automated dependency management.

## Setup

### GitHub App (Recommended)

1. Install the [Renovate GitHub App](https://github.com/apps/renovate) on the repository
2. Renovate will automatically detect `renovate.json` and `.github/renovate.json5`
3. PRs will be created according to the schedule (off-hours only)

### Configuration Files

- **`renovate.json`** - Main configuration
- **`.github/renovate.json5`** - GitHub App-specific overrides
- **`.github/workflows/renovate-config-validator.yml`** - CI validation

## What Gets Updated

### Container Images

#### kasmweb/signal

- Monitors: `kasmweb/signal:*-rolling-daily`
- Auto-merge: Patch updates only
- Labels: `dependencies`, `component: container`

### Helm Dependencies

#### Chart.yaml dependencies

- Monitors: All Helm chart dependencies
- Labels: `dependencies`, `component: helm-chart`

## Schedule

PRs are created during off-hours to avoid disrupting development:

- **Weekdays**: 10pm - 5am ET
- **Weekends**: Any time

**Rate limits:**

- Maximum 2 PRs per hour
- Maximum 10 concurrent PRs

## Auto-merge Strategy

**Enabled for:**

- kasmweb/signal patch updates
- Security updates (Chainguard images)

**Disabled for:**

- Major version bumps
- Minor version bumps
- Vulnerability alerts (require manual review)

## PR Labels

Renovate automatically applies labels for easy triage:

- `dependencies` - All dependency updates
- `component: container` - Container image updates
- `component: helm-chart` - Helm chart updates
- `type: security` - Security-related updates
- `priority: high` - Vulnerability alerts

## Commit Message Format

Renovate uses [Conventional Commits](https://www.conventionalcommits.org/):

```text
chore(deps): update kasmweb/signal to 1.18.1-rolling-daily
```

This integrates with our automated versioning (git-cliff) in CI/CD.

## Validation

The configuration is validated on every push:

```bash
# Local validation
npm install -g renovate
renovate-config-validator
```

CI automatically validates `renovate.json` on PR/push.

## Customization

### Ignoring Dependencies

Add to `ignoreDeps` in `renovate.json`:

```json
{
  "ignoreDeps": ["package-name"]
}
```

### Changing Schedule

Modify `schedule` in `renovate.json`:

```json
{
  "schedule": ["after 10pm", "before 6am", "every weekend"]
}
```

### Disabling Auto-merge

Set `automerge: false` for specific packages in `packageRules`.

## Troubleshooting

### Renovate Not Creating PRs

1. Check if Renovate App is installed: <https://github.com/apps/renovate>
2. Verify config is valid: `renovate-config-validator`
3. Check repository settings allow PR creation
4. Review Renovate logs in "Dependency graph" tab

### Too Many PRs

Adjust rate limits in `renovate.json`:

```json
{
  "prHourlyLimit": 1,
  "prConcurrentLimit": 5
}
```

### Unwanted Updates

Add package to `ignoreDeps` or set `enabled: false` in package rules.

## Resources

- [Renovate Documentation](https://docs.renovatebot.com/)
- [Configuration Options](https://docs.renovatebot.com/configuration-options/)
- [Preset Configs](https://docs.renovatebot.com/presets/)
- [GitHub App](https://github.com/apps/renovate)
