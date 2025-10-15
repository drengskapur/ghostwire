# Changelog

All notable changes to this project will be documented in this file.

## [unreleased]

### Bug Fixes

- **dev:** Update k3d-config ports to avoid conflicts
- **gitops:** Correct GHCR Helm repository URL path
- **gitops:** Remove deprecated oauth2-proxy service.port parameter
- Remove deprecated oauth2-proxy service.port parameter
- Update template reference from signal to ghostwire
- **chart:** Correct NOTES.txt template value references
- **chart:** Use index function for oauth2-proxy value access in NOTES.txt
- **chart:** Remove invalid htpasswd provider from oauth2-proxy config
- **chart:** Correct health probe configuration in StatefulSet
- **gitops:** Reduce PVC size to 2Gi for dev environment disk constraints
- **chart:** Regenerate schema for TCP probes and shmSize
- **chart:** Allow oauth2-proxy subchart properties in schema
- **chart:** Regenerate schema to allow oauth2-proxy subchart flexibility
- Add *.tgz to helmignore and disable auth by default
- Disable oauth2-proxy dependency in Chart.yaml
- **ci:** Extract chart dependencies before linting
- **ci:** Correct GHCR namespace for chart push
- **develop:** Configure oauth2-proxy for htpasswd authentication

### Documentation

- Generate initial CHANGELOG.md
- **dev:** Update README with corrected port mappings
- Document stable tag in Chart.yaml annotations

### Features

- **tasks:** Add dev task for FluxCD GitOps setup
- **dev:** Add direnv configuration for automatic env loading
- **gitops:** Add kustomization manifest for Flux
- **ci:** Add GitHub workflow for Helm chart CI/CD
- **chart:** Update default OAuth2 Proxy credentials
- **chart:** Merge improvements from kasmweb-signal-chart
- Expose oauth2-proxy on port 80 via LoadBalancer
- Configure for HTTPS on port 443 with Cloudflare
- Enhance values schema with comprehensive validation
- Add cloudflared subchart for Cloudflare Tunnel support
- Add cloudflared schema validation
- Enable oauth2-proxy subchart for authentication
- **chart:** Add custom cloudflared deployment template
- **develop:** Add Cloudflare Tunnel automation scripts
- **develop:** Enable tunnel in dev environment
- **develop:** Configure tunnel for direct VNC access
- **develop:** Disable VNC password authentication
- **chart:** Add HAProxy proxy and OAuth2 authentication support
- **develop:** Enable OAuth2 authentication with HAProxy backend

### Miscellaneous Tasks

- Remove git-chglog configuration files
- **gitops:** Update HelmRelease to use chart version 0.1.1
- **gitops:** Update HelmRelease to use chart version 0.1.2
- Add Chart.lock file for oauth2-proxy dependency
- **gitops:** Update HelmRelease to use chart version 0.1.3
- **gitops:** Update HelmRelease to use chart version 0.1.4
- **gitops:** Update HelmRelease to use chart version 0.1.5
- **gitops:** Update HelmRelease to use chart version 0.2.0
- **gitops:** Update HelmRelease to use chart version 0.3.0
- **gitops:** Update HelmRelease to 0.3.1
- **gitops:** Update to 0.3.2
- **deploy:** Update HelmRelease to v0.3.3 with schema fixes
- Ignore helm package tgz files
- Remove Chart.lock file
- Bump chart version to 0.3.8
- Add Chart.lock for cloudflared dependency
- **chart:** Remove cloudflared subchart dependency
- Bump chart version to 0.4.0
- **gitops:** Update HelmRelease to use chart version 0.4.0
- **task:** Add fallback for claude commands
- **chart:** Bump version to 0.5.2

### Refactor

- **tasks:** Simplify dev task to be more concise
- Switch from git-chglog to git-cliff
- **tasks:** Move dev environment tasks to develop/Taskfile.yml
- **tasks:** Remove dev task from root Taskfile
- **dev:** Extract Flux setup script from Taskfile
- Update environment files for ghostwire rebrand
- **dev:** Make Flux setup script configurable via environment
- **ci:** Use working-directory instead of cd in workflow steps
- **chart:** Simplify tunnel configuration
- **chart:** Remove oauth2-proxy dependency
- **develop:** Remove oauth2-proxy from dev environment
- **chart:** Rename templates with resource-type prefix

## [0.1.0] - 2025-10-15

### Bug Fixes

- Update oauth2-proxy image to v7.12.0
- Add missing properties to values schema
- Update remove script to handle both URL formats and add non-interactive mode

### Documentation

- Add comprehensive schema and documentation to Helm chart
- Remove bash script dependencies from chart
- **dev:** Add local development environment guide

### Features

- Add Helm chart for Signal desktop
- Add Taskfile and OCI registry configuration
- **dev:** Add k3d cluster configuration
- **gitops:** Add Flux configuration for development cluster
- **gitops:** Add GHCR Helm repository configuration
- **dev:** Add Ghostwire HelmRelease for k3d cluster
- **tools:** Add changelog generation with git-chglog
- **tasks:** Add changelog generation task

### Miscellaneous Tasks

- Add MCP server config and attribution removal script
- Remove attribution cleanup script
- Add GitHub repository settings
- Add direnv configuration

### Refactor

- Use official OAuth2 Proxy chart as subchart
- Rebrand from signal-system to ghostwire

### Testing

- Add comprehensive Helm unit tests

<!-- generated by git-cliff -->
