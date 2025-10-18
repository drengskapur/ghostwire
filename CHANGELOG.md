# Changelog

All notable changes to this project will be documented in this file.

## [unreleased]

### Bug Fixes

- **ci:** Remove matchUpdateTypes from renovate config
- **tools:** Remove login shell flag from Dockerfile entrypoint
- **ci:** Correct scorecard-action commit hash
- **deps:** Correct renovate helm-values configuration
- **ci:** Correct tools image test command
- **security:** Pin dependencies by hash for supply chain security
- **security:** Apply least privilege principle to workflow token permissions
- **ci:** Only upload ShellCheck SARIF when file exists

### Documentation

- **repo:** Add Contributor Covenant v2.1 code of conduct
- Add OpenSSF Scorecard badge to README
- Document branch protection requirements
- Prepare for OpenSSF Best Practices Badge application
- Address Code-Review score with strategy and co-maintainer call
- Update artifact verification instructions for provenance attestations
- Add comprehensive OpenSSF Best Practices Badge answers guide

### Features

- **ci:** Switch to tag-based releases (standard Helm workflow)
- **scripts:** Add utility scripts for common tasks
- **security:** Improve OpenSSF Scorecard compliance across multiple checks
- **security:** Add StepSecurity harden-runner to audit network egress
- **security:** Complete harden-runner coverage across all workflows
- **security:** Add provenance attestations for release artifacts
- **testing:** Add fuzzing and property-based testing for Helm templates (#18)
- **ci:** Add CodeQL analysis workflow with ShellCheck and YAML linting
- Update GitHub Actions workflow for security and uploads (#20)

### Miscellaneous Tasks

- **docs:** Add markdownlint configuration
- **chart:** Add .markdownlint.json to .helmignore
- **docs:** Add LICENSE and NOTICE to markdownlintignore
- Add OpenSSF Scorecard and Dependabot configuration
- Pin GitHub Actions to commit SHAs for supply chain security
- **ci:** Update github actions to latest versions
- **ci:** Remove obsolete social preview script
- **ci:** Remove manual CodeQL workflow for GitHub native setup
- **ci:** Remove old ossf-scorecard workflow in favor of new scorecard.yml

### Refactor

- **task:** Delegate tasks to standalone scripts
- **ci:** Rename workflow files to idiomatic names

### Styling

- **repo:** Clean up .gitignore formatting
- **docs:** Fix markdown linting violations
- **docs:** Remove trailing blank lines in CODE_OF_CONDUCT.md

## [1.2.3] - 2025-10-18

### Documentation

- Restructure chart README using Bitnami template format

## [1.2.2] - 2025-10-18

### Documentation

- Use latest-stable tag in chart README install examples

## [1.2.1] - 2025-10-18

### Documentation

- Add language specifiers to code fences in chart README

### Performance

- Optimize readiness/liveness probes for faster startup (42s → 12s)

### Testing

- Update probe test expectations for optimized values

## [1.2.0] - 2025-10-18

### Features

- **ci:** Add helm unit tests to chart workflow

## [1.1.2] - 2025-10-18

### Bug Fixes

- Revert Chart.yaml version to 0.0.0-dev for git-cliff workflow

## [1.1.1] - 2025-10-18

### Miscellaneous Tasks

- Regenerate schema with Draft 7 using new config

## [1.1.0] - 2025-10-18

### Bug Fixes

- Auto-convert schema to Draft 7 in Taskfile schema generation

### Features

- Add helm-schema config for Draft 7 and simplify Taskfile

## [1.0.3] - 2025-10-18

### Bug Fixes

- **ci:** Prevent race condition between publish-main and publish-release jobs
- Use JSON Schema Draft 7 for ArtifactHub compatibility

### Miscellaneous Tasks

- Trigger workflow to test package permissions

## [1.0.2] - 2025-10-18

### Documentation

- Remove emoji from chart README features list

## [1.0.1] - 2025-10-18

### Documentation

- **chart:** Add comprehensive metadata for ArtifactHub
- **chart:** Add PGP signing key metadata
- **chart:** Remove changes annotation
- **chart:** Lowercase maintainer name
- Add ArtifactHub badge to README
- Add security policy and vulnerability disclosure process
- Add OCI registry installation instructions to Quick Start
- Remove unnecessary registry login from Quick Start
- Correct Quick Start - VNC auth disabled by default
- Simplify Quick Start - show URL directly without code block
- Make URL copyable with code fence in Quick Start
- Update chart README to use OCI registry and match top-level README

### Miscellaneous Tasks

- **release:** Trigger v1.0.0 release workflow
- Add ArtifactHub repository metadata
- Add ArtifactHub repository ID for verified publisher

## [1.0.0] - 2025-10-18

### Bug Fixes

- Update oauth2-proxy image to v7.12.0
- Add missing properties to values schema
- Update remove script to handle both URL formats and add non-interactive mode
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
- **chart:** Configure HAProxy for HTTPS backend with TCP health checks
- **chart:** Add component label to prevent service routing conflicts
- **ci:** Push chart to correct OCI registry path
- **ci:** Update OCI registry path to charts namespace
- **auth:** Correct VNC username to kasm_user and enhance auth testing
- **ingress:** Use Helm template helpers for service references
- **ci:** Correct GHCR chart path to match Flux HelmRepository
- **ci:** Use v3 for cosign-installer (v4 doesn't exist)
- **ci:** Revert to cosign-installer@v4 (v4.0.0 released Oct 16)
- **ci:** Use full version v4.0.0 for cosign-installer
- **ci:** Use semver-compatible version for main branch (0.0.0-main.{sha})
- **ci:** Capture helm push output to properly extract digest for cosign signing
- **ci:** Add docker login for cosign registry authentication
- **ci:** Use semver-compatible versions for latest tags (0.0.0-latest, 0.0.0-lateststable)
- **ci:** Use correct latest-stable tag format per D2 guide
- **chart:** Remove non-functional auth.username parameter
- **chart:** TLS initContainer and test improvements
- **chart:** Standardize shell command in TLS initContainer
- **chart:** Correct test image references to use tools
- **chart:** Use Chainguard kubectl image for all tests
- **chart:** Add command field to test pod containers
- **chart:** Use tools image with imagePullSecrets for tests
- **chart:** Add global.imagePullSecrets to values schema
- **brand:** Remove light logo variant
- **security:** Allowlist revoked GitHub PAT in security scanners
- **security:** Correct allowlist syntax for TruffleHog and Gitleaks
- **security:** Remove Gitleaks and fix Trivy permissions
- **security:** Simplify TruffleHog and Trivy configurations
- **security:** Fix Trivy and TruffleHog configuration issues
- **security:** Skip scanner config files in Trivy scan

### Documentation

- Add comprehensive schema and documentation to Helm chart
- Remove bash script dependencies from chart
- **dev:** Add local development environment guide
- Generate initial CHANGELOG.md
- **dev:** Update README with corrected port mappings
- Document stable tag in Chart.yaml annotations
- Update CHANGELOG with recent fixes and features
- **chart:** Add authentication retry guidance to NOTES
- **haproxy:** Add comprehensive documentation for optional HAProxy deployment
- Add deployment strategies and Flagger analysis
- Add comprehensive container architecture analysis
- Add Mermaid diagrams to container architecture
- Add cloud-native security design philosophy
- Complete README rewrite emphasizing cloud-native differentiation
- Add quickstart section with default credentials at top
- Add comprehensive gap analysis documentation
- Reframe gap analysis as infrastructure integration guides
- Add third-party attribution and license notices
- Simplify LICENSE footer, remove enterprise notice
- Add comprehensive brand identity guide
- **brand:** Add design critique and refined AI prompts
- **renovate:** Add comprehensive Renovate setup guide
- Standardize documentation filenames to lowercase
- Add centered logo to README header
- Revise README with clearer, more direct language
- Center badges in README header
- Convert architecture diagram from ASCII to Mermaid
- Apply black and white theme to architecture diagram
- Invert architecture diagram to black background
- Separate Quick Start commands for easier copying
- Move screenshot to docs/images directory
- Add screenshot to README header
- Move screenshot to What This Does section

### Features

- Add Helm chart for Signal desktop
- Add Taskfile and OCI registry configuration
- **dev:** Add k3d cluster configuration
- **gitops:** Add Flux configuration for development cluster
- **gitops:** Add GHCR Helm repository configuration
- **dev:** Add Ghostwire HelmRelease for k3d cluster
- **tools:** Add changelog generation with git-chglog
- **tasks:** Add changelog generation task
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
- **develop:** Configure tunnel to route directly to HAProxy
- **develop:** Disable authentication and enable HAProxy for testing
- **chart:** Add Keycloak IAM and improve out-of-box experience
- **chart:** Use OCI registry for Keycloak with SHA digest pinning
- **chart:** Add configurable VNC_USER environment variable
- **chart:** Automate Cloudflare Tunnel secret creation
- **test:** Add Helm tests with custom Wolfi-based debug image
- **test:** Add comprehensive Helm test suite
- **test:** Add VNC authentication configuration test
- **auth:** Update default VNC credentials to testuser/testpass123
- **test:** Add Cloudflare Tunnel external access test
- **security:** Add Network Policies for pod-to-pod communication restrictions
- **tls:** Add support for custom SSL/TLS certificates
- **security:** Enforce Pod Security Standards across all components
- **security:** Add RBAC for HAProxy and Cloudflared components
- **haproxy:** Add SSL verification and health check endpoint
- **config:** Add comprehensive security and feature configuration
- **network-policy:** Support direct Cloudflared→Ghostwire connection when HAProxy disabled
- **proxy:** Add smart proxy service for automatic HAProxy/direct routing
- Add chart version immutability protection
- **ci:** Add GHCR_TOKEN fallback for chart publishing
- **dev:** Add one-command dev environment setup with local access
- **terraform:** Convert to reusable Terraform module
- Add d2-fleet OCI artifact publishing workflow
- Add cosign artifact signing to chart workflow
- **terraform:** Add simplified single-file terraform configuration
- **chart:** Add TLS mode configuration with HTTP-only option
- **chart:** Use rolling-daily image with automatic updates
- **chart:** Increase shared memory to 512MB for Chromium stability
- Add installation notes with keyboard URL parameter
- **chart:** Add JSON schema validation for values.yaml
- **chart:** Add Artifact Hub metadata and discoverability fields
- **brand:** Add official Ghostwire icon
- **chart:** Update icon to official Ghostwire branding
- **brand:** Add complete brand asset suite
- **brand:** Add dark and light logo variants
- **brand:** Finalize brand assets with optimal sizing and consistency
- **github:** Add social preview configuration

### Miscellaneous Tasks

- Add MCP server config and attribution removal script
- Remove attribution cleanup script
- Add GitHub repository settings
- Add direnv configuration
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
- Bump chart version to 0.7.0
- Remove schema.sh script (now embedded in Taskfile)
- Remove obsolete htpasswd script
- **schema:** Regenerate JSON schema for new configuration options
- **schema:** Regenerate JSON schema with nameOverride/fullnameOverride
- **flux:** Bump HelmRelease to chart version 0.8.0
- Cleanup repository and fix git-cliff config
- Add concurrency control to chart workflow
- Remove terraform configuration
- Update cosign-installer to v4.0.0
- Use major version refs for GitHub Actions
- Remove develop directory
- Remove values.schema.json to simplify workflow
- **chart:** Prepare v0.1.0 release
- **chart:** Reset version to 0.0.0-dev for workflow-based versioning
- Enhance GitHub repository settings configuration
- Add comprehensive security scanning workflow
- Remove commercial license reference from Gitleaks config
- Prepare repository for open source release
- Configure trunk-based development branch protection
- Add VS Code workspace configuration
- **taskfile:** Remove CI/CD-managed tasks and unused variables
- **renovate:** Add configuration validator workflow
- **renovate:** Add GitHub-specific config for Renovate App
- Remove unused Gitleaks configuration files
- **release:** Bump chart version to 1.0.0

### Refactor

- Use official OAuth2 Proxy chart as subchart
- Rebrand from signal-system to ghostwire
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
- **chart:** Remove Keycloak/auth, use built-in VNC basic auth
- **chart:** Restructure VNC configuration to be more idiomatic
- **chart:** Use idiomatic auth structure for VNC credentials
- **taskfile:** Embed schema script and update OCI paths
- **chart:** Make HAProxy server name generic
- **terraform:** Make module idiomatic and fix cloud-init
- **chart:** Remove Cloudflare Tunnel support
- **chart:** Remove Cloudflare Tunnel from values and templates
- **chart:** Remove network policy
- Reorganize to idiomatic structure with Apache 2.0 license
- **ci:** Split into component-specific workflows
- **chart:** Remove ingress template
- **chart:** Use Chainguard kubectl image for TLS test
- Remove .env files for professional OSS project structure

### Styling

- **chart:** Fix YAML indentation and sort .helmignore
- Trim trailing whitespace

### Testing

- Add comprehensive Helm unit tests
- **chart:** Update helm unittests for auth refactoring
- **chart:** Add comprehensive tests for cloudflared and HAProxy
- Add comprehensive unit tests for new security features
- **chart:** Add comprehensive TLS mode and regression tests
- **chart:** Add runtime integration test for custom TLS certificates

<!-- generated by git-cliff -->
