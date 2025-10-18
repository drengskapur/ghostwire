# Ghostwire Signal Desktop Image

Signal Desktop on Wolfi Linux with VNC/noVNC access, built for cloud-native deployments.

## Features

- **Wolfi Linux base** - Minimal, secure, glibc-based
- **Signal Desktop** - Latest version from official APT repository
- **VNC access** - x11vnc + noVNC for browser-based access
- **Single-app mode** - OpenBox window manager optimized for Signal
- **Auto-restart** - Supervisor handles Signal crashes gracefully
- **KasmVNC-compatible** - Same ports, paths, and environment variables

## Quick Start

### Build

```bash
docker build -t ghostwire/signal:latest images/signal/
```

### Run

```bash
docker run -d \
  --name signal \
  -p 6901:6901 \
  -v signal-data:/home/kasm-user/.config/Signal \
  ghostwire/signal:latest
```

### Access

Open in browser: `http://localhost:6901/vnc.html?keyboard=1`

Default credentials: No password (add with `-e VNC_PASSWORD=yourpassword`)

## Architecture

```
Xvfb (:1) → x11vnc (5901) → websockify (6901) → Browser
     ↓
  OpenBox
     ↓
Signal Desktop (--no-sandbox)
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DISPLAY` | `:1` | X11 display number |
| `VNC_PORT` | `5901` | VNC server port |
| `NOVNC_PORT` | `6901` | noVNC/websockify port |
| `VNC_RESOLUTION` | `1280x720` | Screen resolution |
| `VNC_COL_DEPTH` | `24` | Color depth |
| `VNC_PASSWORD` | (none) | VNC password for authentication |
| `MAXIMIZE` | `true` | Auto-maximize Signal window |
| `MAX_RESTARTS` | `999` | Maximum Signal restart attempts |

## Persistent Storage

Mount `/home/kasm-user/.config/Signal` to persist:
- Messages and conversations
- Linked device information
- Application settings
- Media and attachments

## Compatibility

Drop-in replacement for `kasmweb/signal`:
- Same port (6901)
- Same user (kasm-user, UID 1000)
- Same paths (/dockerstartup, /home/kasm-user)
- Same environment variables

## Security

- Runs as non-root user (kasm-user)
- Signal runs with `--no-sandbox` (required in containers)
- No default VNC password (set `VNC_PASSWORD` for authentication)
- Built on Wolfi for minimal attack surface

## License

Apache 2.0 - See [LICENSE](../../LICENSE)
