# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, report them via GitHub's private vulnerability reporting:

1. Go to the [Security Advisories](https://github.com/drengskapur/ghostwire/security/advisories) page
2. Click "Report a vulnerability"
3. Fill out the advisory form with details

Alternatively, email security reports to: **<security@drengskapur.com>**

### What to Include

- Description of the vulnerability
- Steps to reproduce the issue
- Affected versions
- Potential impact
- Suggested fixes (if any)

### What to Expect

- **Initial response:** Within 48 hours
- **Status update:** Within 7 days
- **Fix timeline:** Varies by severity (critical issues prioritized)

We follow coordinated disclosure and will credit reporters in security advisories unless anonymity is requested.

## Security Considerations

### Default Credentials

The chart ships with default VNC credentials for convenience:

- Username: `kasm_user`
- Password: `CorrectHorseBatteryStaple`

**Change these immediately for any exposed deployment.**

### Authentication

This chart does **not** provide built-in authentication beyond basic VNC credentials. For production use:

- Deploy behind OAuth2 proxy (oauth2-proxy, Pomerium, etc.)
- Use network policies to restrict access
- Enable TLS termination via ingress controller
- Consider IP allowlisting

See [Infrastructure Integration Guide](docs/infrastructure-integration-guide.md) for recommended patterns.

### Network Exposure

By default, the chart creates a ClusterIP service. To expose externally:

- Use kubectl port-forward for local development only
- Configure ingress with authentication for production
- Apply network policies to restrict pod communication
- Enable audit logging at the cluster level

### Container Security

The chart uses third-party container images:

- Base: [kasmweb/signal](https://hub.docker.com/r/kasmweb/signal)
- Upstream: [Signal Desktop](https://github.com/signalapp/Signal-Desktop)

**Artifact verification:**

All Helm charts are cryptographically signed and attested:

- **OCI artifacts** (GHCR): Signed with Cosign keyless signing
  ```bash
  cosign verify ghcr.io/drengskapur/charts/ghostwire:1.0.0 \
    --certificate-identity-regexp='^https://github.com/drengskapur/ghostwire/' \
    --certificate-oidc-issuer=https://token.actions.githubusercontent.com
  ```

- **GitHub Releases**: Signed with SLSA provenance attestations
  ```bash
  gh attestation verify ghostwire-1.0.0.tgz --owner drengskapur
  ```

- **Manual verification**: Download and verify attestations
  ```bash
  # Download release artifact
  wget https://github.com/drengskapur/ghostwire/releases/download/v1.0.0/ghostwire-1.0.0.tgz

  # Verify provenance attestation
  gh attestation verify ghostwire-1.0.0.tgz -o drengskapur
  ```

### Data Persistence

Signal data is stored in a PersistentVolumeClaim:

- Contains encryption keys, message history, and credentials
- Survives pod restarts and redeployments
- **Backup this volume** - losing it requires re-linking the device

Ensure your storage class provides:

- Encryption at rest
- Regular snapshots
- Access controls

### Kubernetes Security Context

The chart runs containers with restrictive security contexts by default:

- Non-root user (UID 1000)
- Read-only root filesystem where possible
- Capability dropping
- No privilege escalation

Review `values.yaml` for security context configuration.

## Security Scanning

This repository uses automated security scanning:

- **TruffleHog:** Secret detection in git history
- **Trivy:** Vulnerability scanning for dependencies and misconfigurations
- **Dependency Review:** License and vulnerability checks on dependencies

Scan results are available in [GitHub Actions](https://github.com/drengskapur/ghostwire/actions).

## Known Limitations

1. **VNC Protocol:** Unencrypted by default - TLS termination must occur at ingress
2. **Signal Desktop:** Requires manual device linking via QR code
3. **Browser Access:** Susceptible to clickjacking without proper CSP headers
4. **Resource Limits:** No default limits - configure based on your threat model

## Third-Party Security

This project integrates:

- **Signal Desktop** (AGPLv3) - E2E encrypted messaging
- **Kasm Workspaces** (MIT) - Container streaming platform
- **KasmVNC** (GPLv2) - VNC server implementation

Security issues in upstream dependencies should be reported to their respective maintainers.

## Compliance

This Helm chart does not make specific compliance claims. Users are responsible for:

- Evaluating suitability for their compliance requirements
- Implementing required controls (audit logging, access controls, etc.)
- Reviewing and accepting third-party licenses
- Configuring the deployment to meet organizational policies

## Security Updates

Security fixes are released as:

- Patch versions for backports (e.g., 1.0.1)
- Minor versions for non-breaking mitigations (e.g., 1.1.0)
- Major versions for breaking security changes (e.g., 2.0.0)

Subscribe to [GitHub Releases](https://github.com/drengskapur/ghostwire/releases) or watch the repository for notifications.
