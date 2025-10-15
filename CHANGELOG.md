<a name="unreleased"></a>
## [Unreleased]


<a name="v0.1.0"></a>
## v0.1.0 - 2025-10-15
### Bug Fixes
- update remove script to handle both URL formats and add non-interactive mode
- add missing properties to values schema
- update oauth2-proxy image to v7.12.0

### Code Refactoring
- rebrand from signal-system to ghostwire
- use official OAuth2 Proxy chart as subchart

### Features
- add Taskfile and OCI registry configuration
- add Helm chart for Signal desktop
- **dev:** add Ghostwire HelmRelease for k3d cluster
- **dev:** add k3d cluster configuration
- **gitops:** add GHCR Helm repository configuration
- **gitops:** add Flux configuration for development cluster
- **tasks:** add changelog generation task
- **tools:** add changelog generation with git-chglog


[Unreleased]: https://github.com/drengskapur/ghostwire/compare/v0.1.0...HEAD
