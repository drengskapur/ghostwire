# Ghostwire - Signal Desktop with VNC

Containerized Signal Desktop with VNC access, built on Chainguard Wolfi for enhanced security.

## Key Improvements Over Kasm

✅ **Security-First**: Chainguard Wolfi base instead of Ubuntu
✅ **Minimal Attack Surface**: Only necessary packages from Wolfi repos
✅ **Single Image**: No complex base image layering
✅ **Built-in Healthcheck**: Automatic container health monitoring
✅ **Clean Architecture**: Simplified process management with supervisord
✅ **Better Logging**: All services log to stdout/stderr for container-native logging
✅ **Proper Signal Handling**: Graceful shutdown on SIGTERM

## Architecture

```plaintext
┌──────────────────────────────────────────┐
│   Chainguard Wolfi (Minimal, Secure)     │
├──────────────────────────────────────────┤
│  Supervisor (Process Manager)            │
│    ├─> Xvfb (Virtual Display :1)         │
│    ├─> OpenBox (Window Manager)          │
│    ├─> x11vnc (VNC Server :5901)         │
│    ├─> noVNC (Web Client :6901)          │
│    └─> Signal Desktop                    │
└──────────────────────────────────────────┘
```

## Quick Start

```bash
# Build locally
task build-local

# Run with persistent data
task test

# Access in browser
open http://localhost:6901
```

## Features

- **Non-root execution**: Runs as `ghostwire` user (uid:1000)
- **Persistent storage**: Signal data in `/home/ghostwire/.config/Signal`
- **Browser access**: noVNC at port 6901
- **Direct VNC**: Standard VNC at port 5901
- **Health monitoring**: Built-in healthcheck validates all services

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DISPLAY` | `:1` | X11 display number |
| `VNC_PORT` | `5901` | VNC server port |
| `NOVNC_PORT` | `6901` | noVNC web interface port |
| `VNC_RESOLUTION` | `1280x720` | Screen resolution |
| `VNC_COL_DEPTH` | `24` | Color depth (bits) |

## Exposed Ports

- **5901**: VNC server (for VNC clients)
- **6901**: noVNC web interface (for browsers)

## Data Persistence

Mount a volume to persist Signal Desktop data across container restarts:

```bash
docker run -d \
  -p 6901:6901 \
  -v ghostwire-data:/home/ghostwire/.config/Signal \
  ghcr.io/drengskapur/ghostwire:latest
```

## Task Commands

```bash
task build-local    # Build for local testing
task test           # Run test container
task logs           # View logs
task stop           # Stop test container
task clean          # Clean up images and builder
task clean-data     # Remove data volume
task dev            # Build and run in one command
```

## Security

- **Wolfi Linux**: Minimal, security-focused base from Chainguard
- **Non-root**: Runs as unprivileged user (uid:1000)
- **No VNC password**: Designed to run behind OAuth2 proxy in production
- **Signal sandboxing**: Disabled (`--no-sandbox`) as required for containers

## Production Deployment

This image is designed to be deployed via the Ghostwire Helm chart:

```bash
helm install ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  --namespace ghostwire \
  --create-namespace
```

The Helm chart handles:

- OAuth2 authentication (via oauth2-proxy)
- TLS termination (via cert-manager)
- Ingress configuration
- Persistent volume claims
- Network policies

See [main README](../../README.md) for full deployment documentation.

## Differences from Kasm

| Aspect | Kasm | Ghostwire |
|--------|------|-----------|
| Base OS | Ubuntu 20.04/22.04 | Chainguard Wolfi |
| Architecture | Base image + app layers | Single self-contained image |
| Package count | ~1000+ packages | <100 packages |
| User management | Complex multi-user | Simple single-user |
| VNC | KasmVNC (custom fork) | x11vnc + noVNC (standard) |
| Healthcheck | None | Built-in |
| CVE exposure | High (Ubuntu) | Minimal (Wolfi) |

## License

Apache 2.0 - See [LICENSE](../../LICENSE)

## Attribution

- **Signal Desktop**: AGPLv3 (Signal Messenger LLC)
- **noVNC**: MPL 2.0 (noVNC contributors)
- **Wolfi**: Apache 2.0 (Chainguard)
