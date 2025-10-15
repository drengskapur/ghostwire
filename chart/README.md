# Ghostwire - Signal Desktop Helm Chart

Secure deployment system for Signal Desktop using KasmWeb VNC with OAuth2 Proxy authentication.

## Features

- **StatefulSet deployment** for persistent Signal data
- **OAuth2 Proxy authentication** with WebSocket support for VNC
- **Custom login page** with modern UI
- **Session management** with configurable timeouts
- **Persistent storage** for Signal database and configuration
- **Ingress support** with proper WebSocket annotations
- **Health probes** for VNC interface availability

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PersistentVolume provisioner support (for data persistence)
- (Optional) Ingress controller with WebSocket support (e.g., NGINX Ingress)
- (Optional) cert-manager for TLS certificates

## Installation

### Quick Start

```bash
# Install with default values (uses auth with default password)
helm install signal ./chart

# Install without authentication
helm install signal ./chart --set auth.enabled=false

# Install with custom domain and TLS
helm install signal ./chart \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=signal.example.com \
  --set ingress.tls[0].secretName=signal-tls \
  --set ingress.tls[0].hosts[0]=signal.example.com
```

### Configure Authentication

1. Generate htpasswd entries:

```bash
htpasswd -nbB admin MySecurePassword
```

2. Generate cookie secret:

```bash
openssl rand -base64 32
```

3. Create `custom-values.yaml`:

```yaml
auth:
  enabled: true
  cookieSecret: "YOUR_32_BYTE_COOKIE_SECRET"
  users:
    - "admin:$2y$05$..."  # Output from generate-htpasswd.sh
    - "user1:$2y$05$..."  # Additional users
```

4. Install with custom values:

```bash
helm install signal ./chart -f custom-values.yaml
```

## Configuration

### Key Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Signal container image | `kasmweb/signal` |
| `image.tag` | Signal image tag | `1.18.0` |
| `replicaCount` | Number of replicas | `1` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | VNC port | `6901` |
| `persistence.enabled` | Enable persistent storage | `true` |
| `persistence.size` | Storage size | `10Gi` |
| `auth.enabled` | Enable OAuth2 Proxy | `true` |
| `auth.cookieSecret` | OAuth2 cookie secret | `CHANGE_ME...` |
| `auth.cookieExpire` | Session expiration | `8h` |
| `auth.cookieRefresh` | Session refresh interval | `1h` |
| `auth.users` | htpasswd user entries | `["admin:..."]` |
| `ingress.enabled` | Enable ingress | `false` |

### Authentication Configuration

#### Adding Users

Generate htpasswd entries:

```bash
htpasswd -nbB username password
```

Add to `values.yaml`:

```yaml
auth:
  users:
    - "username:$2y$05$..."
```

#### Custom Login Page

Customize the login page appearance:

```yaml
auth:
  customLoginPage:
    enabled: true
    title: "Custom Title"
    subtitle: "Custom subtitle message"
```

#### Session Management

Configure session duration for VNC usage:

```yaml
auth:
  cookieRefresh: "1h"   # Refresh session every hour
  cookieExpire: "8h"    # Total session duration
  sessionAffinity:
    enabled: true
    timeoutSeconds: 3600  # 1 hour sticky sessions
```

### Resource Limits

#### Signal Container

```yaml
resources:
  limits:
    cpu: 2000m
    memory: 4Gi
  requests:
    cpu: 500m
    memory: 1Gi
```

#### OAuth2 Proxy

```yaml
auth:
  resources:
    limits:
      cpu: 200m
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 128Mi
```

### Ingress Configuration

#### With NGINX Ingress Controller

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: signal.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: signal-tls
      hosts:
        - signal.example.com
```

The chart automatically adds WebSocket-specific annotations when `auth.enabled=true`:
- Extended timeouts for VNC sessions
- WebSocket service configuration
- Proper buffering and keepalive settings

### LoadBalancer with Reserved IP

For DigitalOcean or cloud providers with reserved IPs:

```yaml
service:
  type: LoadBalancer
  loadBalancerIP: "your.reserved.ip"
```

## Usage

### Accessing Signal

1. **With Authentication (default):**
   - Navigate to your ingress URL or service endpoint
   - Log in with configured username/password
   - VNC interface loads automatically

2. **Without Authentication:**
   - Direct access to VNC on port 6901
   - Default VNC password: `password` (change this!)

### First-Time Setup

1. Link Signal to your phone number
2. Scan QR code with Signal mobile app
3. Signal data persists in PersistentVolume

### Managing Users

#### Add User

```bash
# Generate entry
htpasswd -nbB newuser password

# Update values and upgrade
helm upgrade signal ./chart -f custom-values.yaml
```

#### Remove User

Edit `values.yaml` and remove the user entry, then upgrade:

```bash
helm upgrade signal ./chart -f custom-values.yaml
```

### Changing Passwords

1. Generate new htpasswd entry
2. Update `values.yaml`
3. Upgrade the release:

```bash
helm upgrade signal ./chart -f custom-values.yaml
```

## Troubleshooting

### Authentication Loop

If experiencing redirect loops:

1. Check cookie secret is properly set:
   ```bash
   kubectl get secret signal-auth -o jsonpath='{.data.cookie-secret}' | base64 -d
   ```

2. Verify ingress annotations include WebSocket support

3. Check OAuth2 Proxy logs:
   ```bash
   kubectl logs -l app.kubernetes.io/component=auth-proxy
   ```

### VNC Connection Issues

1. Verify WebSocket annotations in ingress:
   ```bash
   kubectl get ingress signal -o yaml
   ```

2. Check Signal logs:
   ```bash
   kubectl logs -l app.kubernetes.io/name=signal
   ```

3. Test direct access (port-forward):
   ```bash
   kubectl port-forward svc/signal 6901:6901
   # Access http://localhost:6901
   ```

### Persistence Issues

Check PVC status:

```bash
kubectl get pvc
kubectl describe pvc signal-data-signal-0
```

## Architecture

```
User → Ingress → OAuth2 Proxy → Signal VNC (KasmWeb)
                      ↓
                  htpasswd auth
                  WebSocket passthrough
                  Session management
```

- **OAuth2 Proxy** handles authentication with htpasswd provider
- **WebSocket support** ensures VNC streaming works properly
- **Session affinity** keeps users on the same pod
- **Extended timeouts** prevent VNC disconnections

## Security Considerations

1. **Change default passwords:**
   - OAuth2 Proxy cookie secret
   - VNC password
   - htpasswd user credentials

2. **Use TLS/HTTPS:**
   - Enable ingress TLS
   - Use cert-manager for automated certificates

3. **Restrict access:**
   - Use ingress with authentication
   - Consider IP whitelisting
   - Use strong passwords (bcrypt hash)

4. **Session management:**
   - Configure appropriate session timeouts
   - Enable session affinity for VNC stability

## Upgrading

```bash
# Upgrade with new values
helm upgrade signal ./chart -f custom-values.yaml

# Upgrade to new chart version
helm upgrade signal ./chart --version x.y.z
```

**Note:** StatefulSet spec changes may require manual intervention. Check release notes before upgrading.

## Uninstalling

```bash
# Delete release
helm uninstall signal

# Persistent data remains - delete manually if needed
kubectl delete pvc signal-data-signal-0
```

## Development

### Testing Locally

```bash
# Lint chart
helm lint ./chart

# Template rendering
helm template signal ./chart -f custom-values.yaml

# Dry run
helm install signal ./chart --dry-run --debug
```

### Generate Password

```bash
# Generate htpasswd entry
htpasswd -nbB username password

# Generate cookie secret
openssl rand -base64 32
```

## Support

- **Chart Repository:** https://github.com/drengskapur/ghostwire
- **KasmWeb Documentation:** https://www.kasmweb.com/docs
- **OAuth2 Proxy:** https://oauth2-proxy.github.io/oauth2-proxy/

## License

This Helm chart is provided as-is for deploying Signal Desktop with KasmWeb.
