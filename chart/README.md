# Ghostwire

**Cloud-native Signal Desktop for Kubernetes** - Browser-based access with infrastructure-level security.

---

## Quickstart

**Get Signal Desktop running in 60 seconds:**

```bash
# Install
helm install ghostwire ./chart --create-namespace -n ghostwire

# Access
kubectl port-forward -n ghostwire svc/ghostwire 6901:6901

# Open browser
open http://localhost:6901?keyboard=1
```

**Default credentials (when auth is enabled):**
- Username: `kasm_user`
- Password: `CorrectHorseBatteryStaple`

**⚠️ For production:** Disable built-in auth and use ingress + OAuth2 instead (see [Production Setup](#production-setup))

---

## Why Ghostwire?

Unlike traditional VNC deployments that bake security into the application, **Ghostwire is designed to be a well-behaved cloud-native citizen** that integrates cleanly with your existing Kubernetes security infrastructure.

### The Cloud-Native Difference

**Traditional Approach** (most VNC/remote desktop solutions):
```
❌ VNC password → manage/rotate credentials per app
❌ Self-signed certs → browser warnings, manual cert injection
❌ Double authentication → login to ingress, then VNC password again
❌ Per-app TLS config → certificate gymnastics for each service
❌ Fragmented observability → auth logs scattered across apps
```

**Ghostwire's Approach** (cloud-native):
```
✅ No built-in auth → use your existing OAuth2/OIDC provider
✅ No built-in TLS → cert-manager + Let's Encrypt at ingress
✅ Single sign-on → authenticate once, access everything
✅ Infrastructure security → network policies, service mesh, ingress
✅ Centralized observability → all auth/access logs in one place
```

### What You Get

Run Signal Desktop in your Kubernetes cluster with:

- **🔐 Infrastructure-Level Security** - OAuth2, cert-manager, service mesh integration
- **💾 Persistent Storage** - Conversations survive pod restarts (StatefulSet + PVC)
- **🌐 Browser Access** - No VNC client needed (KasmVNC web client)
- **📱 Mobile-Friendly** - On-screen keyboard support (`?keyboard=1` URL parameter)
- **☁️ Cloud-Native** - Leverages platform capabilities instead of reinventing them

---

## TL;DR - Quick Start

### Local Development (port-forward)

```bash
# Install with defaults (no auth, for local use)
helm install ghostwire ./chart --create-namespace -n ghostwire

# Forward port
kubectl port-forward -n ghostwire svc/ghostwire 6901:6901

# Open browser
open http://localhost:6901?keyboard=1
```

### Production (with ingress + OAuth2)

```yaml
# values-production.yaml
auth:
  enabled: false  # Auth handled by OAuth2-proxy at ingress

tls:
  mode: disabled  # TLS handled by ingress controller

service:
  type: ClusterIP

persistence:
  size: 15Gi
  storageClass: fast-ssd

resources:
  requests:
    memory: 1Gi
    cpu: 500m
  limits:
    memory: 2Gi
    cpu: 1500m
```

```bash
helm install ghostwire ./chart -f values-production.yaml -n ghostwire
```

Then deploy an ingress with TLS + OAuth2 (see [Production Setup](#production-setup) below).

---

## Production Setup

This is the **recommended way** to run Ghostwire in production.

### Architecture

```
Internet → Ingress (TLS + OAuth2) → ClusterIP Service → Ghostwire Pod
           ↓                          ↓
     cert-manager              Network Policy
     Let's Encrypt             (optional isolation)
     OAuth2-proxy
```

**Security is handled by Kubernetes infrastructure, not the application.**

### Step 1: Install Ghostwire

```bash
helm install ghostwire ./chart -n ghostwire \
  --set auth.enabled=false \
  --set tls.mode=disabled \
  --set service.type=ClusterIP
```

### Step 2: Deploy Ingress with TLS + OAuth2

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ghostwire
  namespace: ghostwire
  annotations:
    # TLS via cert-manager
    cert-manager.io/cluster-issuer: letsencrypt-prod

    # Authentication via OAuth2-proxy
    nginx.ingress.kubernetes.io/auth-url: "https://oauth2.example.com/oauth2/auth"
    nginx.ingress.kubernetes.io/auth-signin: "https://oauth2.example.com/oauth2/start?rd=$scheme://$host$request_uri"

    # WebSocket support (required for VNC)
    nginx.ingress.kubernetes.io/websocket-services: "ghostwire"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - signal.company.com
    secretName: ghostwire-tls  # Auto-created by cert-manager
  rules:
  - host: signal.company.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ghostwire
            port:
              number: 6901
```

### Step 3: (Optional) Add Network Policy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ghostwire-ingress-only
  namespace: ghostwire
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: ghostwire
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx  # Only allow ingress controller
    ports:
    - protocol: TCP
      port: 6901
```

### Result

**Users now experience:**
- ✅ Single sign-on via Google/GitHub/OIDC (no VNC password)
- ✅ Valid TLS certificate (no browser warnings)
- ✅ Standard ingress access patterns
- ✅ Centralized auth logs and metrics
- ✅ No credential management burden

**Admins get:**
- ✅ Consistent security policies across all apps
- ✅ Automatic certificate rotation (cert-manager)
- ✅ Unified access control (OAuth2-proxy)
- ✅ Standard Kubernetes tooling
- ✅ No per-app security configuration

---

## Installation Methods

### Method 1: Helm Install (Recommended)

```bash
# From local chart
helm install ghostwire ./chart \
  --create-namespace \
  --namespace ghostwire

# From OCI registry (if published)
helm install ghostwire oci://ghcr.io/drengskapur/ghostwire \
  --version 0.0.0-latest-stable \
  --namespace ghostwire
```

### Method 2: Flux CD (GitOps)

```yaml
# oci-repository.yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: OCIRepository
metadata:
  name: ghostwire-chart
  namespace: flux-system
spec:
  interval: 5m
  url: oci://ghcr.io/drengskapur/ghostwire
  ref:
    tag: 0.0.0-latest-stable
---
# helmrelease.yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: ghostwire
  namespace: ghostwire
spec:
  interval: 10m
  chart:
    spec:
      chart: ghostwire
      version: 0.0.0-latest-stable
      sourceRef:
        kind: OCIRepository
        name: ghostwire-chart
        namespace: flux-system
  values:
    auth:
      enabled: false
    tls:
      mode: disabled
    persistence:
      enabled: true
      size: 15Gi
```

---

## Configuration

### Cloud-Native Defaults

| Parameter | Default | Cloud-Native Value | Why |
|-----------|---------|-------------------|-----|
| `auth.enabled` | `false` | `false` | Auth at ingress (OAuth2-proxy) |
| `tls.mode` | `disabled` | `disabled` | TLS at ingress (cert-manager) |
| `service.type` | `ClusterIP` | `ClusterIP` | Internal-only, exposed via ingress |

### Resource Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `resources.requests.memory` | `1Gi` | Minimum memory (Signal Desktop baseline) |
| `resources.limits.memory` | `2Gi` | Maximum memory (prevents runaway usage) |
| `resources.requests.cpu` | `500m` | Minimum CPU (0.5 cores) |
| `resources.limits.cpu` | `2000m` | Maximum CPU (2 cores) |

### Persistence Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `persistence.enabled` | `true` | Enable persistent storage (required for Signal data) |
| `persistence.size` | `10Gi` | PVC size (messages, attachments, cache) |
| `persistence.storageClass` | `""` | Use cluster default (or specify fast SSD) |
| `persistence.accessMode` | `ReadWriteOnce` | Single-node access (StatefulSet requirement) |

### Display Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `display.resolution` | `1280x720` | Initial VNC resolution (resizable in browser) |

### Advanced Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `shmSize` | `512` | Shared memory in MB (for browser rendering) |
| `env` | `[]` | Additional environment variables |
| `nodeSelector` | `{}` | Node selection constraints |
| `tolerations` | `[]` | Pod tolerations |
| `affinity` | `{}` | Pod affinity rules |

**Full configuration reference**: See [values.yaml](values.yaml) for all 60+ configurable parameters.

---

## Accessing Signal

### First-Time Setup

1. **Access the VNC interface** (via ingress or port-forward)
2. **Open Signal Desktop** (should auto-start in the VNC session)
3. **Link your device**:
   - On your phone, open Signal → Settings → Linked Devices → Add Device
   - Scan the QR code displayed in the browser
   - Name it "Ghostwire" or "Signal on Kubernetes"

**Your Signal data is now stored in the PersistentVolume** and will survive pod restarts.

### Daily Use

**Production (with ingress)**:
```
https://signal.company.com?keyboard=1
```
- Log in via OAuth2 (once)
- Access Signal Desktop instantly
- On-screen keyboard works on mobile

**Local development (port-forward)**:
```bash
kubectl port-forward -n ghostwire svc/ghostwire 6901:6901
```
Then open: `http://localhost:6901?keyboard=1`

---

## When to Use Built-in Auth/TLS

The chart **supports** built-in VNC authentication and TLS, but it's **not the default** for good reason.

### Use built-in auth/TLS when:

✅ **Local development and testing**
```bash
helm install ghostwire ./chart --set auth.enabled=true --set auth.password=dev123
```

✅ **Air-gapped environments** (no ingress controller)
```bash
helm install ghostwire ./chart \
  --set auth.enabled=true \
  --set tls.mode=auto \
  --set service.type=LoadBalancer
```

✅ **Quick demos and POCs**
```bash
helm install ghostwire ./chart --set auth.password=demo123
kubectl port-forward svc/ghostwire 6901:6901
```

### Custom TLS Certificate Example

```bash
# Create secret with your certificate
kubectl create secret tls ghostwire-tls \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key \
  -n ghostwire

# Install with custom cert
helm install ghostwire ./chart \
  --set tls.mode=custom \
  --set tls.secretName=ghostwire-tls \
  --set auth.password=secure123
```

---

## Common Tasks

### View Logs

```bash
# Real-time logs
kubectl logs -n ghostwire ghostwire-0 -f

# Last 100 lines
kubectl logs -n ghostwire ghostwire-0 --tail=100

# Search for errors
kubectl logs -n ghostwire ghostwire-0 | grep -i error
```

### Check Pod Status

```bash
# Pod status
kubectl get pod -n ghostwire ghostwire-0

# Detailed info
kubectl describe pod -n ghostwire ghostwire-0

# Resource usage
kubectl top pod -n ghostwire ghostwire-0
```

### Inspect Signal Data

```bash
# List Signal data directory
kubectl exec -n ghostwire ghostwire-0 -- ls -la /home/kasm-user/.config/Signal

# Check database size
kubectl exec -n ghostwire ghostwire-0 -- du -sh /home/kasm-user/.config/Signal

# View logs
kubectl exec -n ghostwire ghostwire-0 -- tail -f /home/kasm-user/.config/Signal/logs/main.log
```

### Increase Storage

```bash
# Patch PVC (if your StorageClass supports expansion)
kubectl patch pvc -n ghostwire signal-data-ghostwire-0 \
  -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'

# Verify expansion
kubectl get pvc -n ghostwire
```

### Backup Signal Data

```bash
# Create backup pod
kubectl run ghostwire-backup --rm -it \
  --image=busybox \
  --overrides='
{
  "spec": {
    "containers": [{
      "name": "backup",
      "image": "busybox",
      "command": ["tar", "czf", "/backup/signal-backup.tar.gz", "-C", "/data", "."],
      "volumeMounts": [{
        "name": "data",
        "mountPath": "/data"
      }, {
        "name": "backup",
        "mountPath": "/backup"
      }]
    }],
    "volumes": [{
      "name": "data",
      "persistentVolumeClaim": {"claimName": "signal-data-ghostwire-0"}
    }, {
      "name": "backup",
      "emptyDir": {}
    }]
  }
}' -n ghostwire

# Copy backup out
kubectl cp ghostwire-backup:/backup/signal-backup.tar.gz ./signal-backup.tar.gz -n ghostwire
```

---

## Troubleshooting

### Signal Desktop Won't Start

**Check pod logs**:
```bash
kubectl logs -n ghostwire ghostwire-0 | grep -E "(ERROR|signal-desktop)"
```

**Common issues**:
- Insufficient memory → Increase `resources.limits.memory`
- GPU initialization errors → Expected (falls back to software rendering)
- D-Bus errors → Expected (only session bus needed)

### VNC Shows Blank Screen

1. **Verify pod is running**:
   ```bash
   kubectl get pod -n ghostwire ghostwire-0
   ```

2. **Check resource usage**:
   ```bash
   kubectl top pod -n ghostwire ghostwire-0
   ```

3. **Increase shared memory** if browser crashes:
   ```bash
   helm upgrade ghostwire ./chart --set shmSize=1024 --reuse-values
   ```

### Authentication Issues (when enabled)

**Browser caches VNC credentials**. To reset:
- Open incognito/private window, OR
- Clear browser data (Ctrl+Shift+Delete → Cached images and files)

### Persistent Data Loss

**Check PVC status**:
```bash
kubectl get pvc -n ghostwire
kubectl describe pvc -n ghostwire signal-data-ghostwire-0
```

**Common causes**:
- PVC not bound → Check StorageClass availability
- Pod deleted with PVC → Verify `helm uninstall` didn't delete PVC
- Node failure → Check PV access mode and node availability

### WebSocket Connection Fails (Ingress)

**Verify ingress annotations**:
```bash
kubectl get ingress -n ghostwire ghostwire -o yaml
```

**Required for NGINX ingress**:
```yaml
nginx.ingress.kubernetes.io/websocket-services: "ghostwire"
nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
```

---

## Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────┐
│                      Ingress Layer                      │
│  (TLS termination, OAuth2, cert-manager, Let's Encrypt) │
└────────────────────┬────────────────────────────────────┘
                     │
                     ├─ HTTPS/WSS (authenticated)
                     ↓
┌─────────────────────────────────────────────────────────┐
│                   Kubernetes Service                    │
│              (ClusterIP, port 6901)                     │
└────────────────────┬────────────────────────────────────┘
                     │
                     ├─ Internal routing
                     ↓
┌─────────────────────────────────────────────────────────┐
│                 Ghostwire StatefulSet                   │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Pod: ghostwire-0                                 │  │
│  │  ├─ Xvnc (VNC server + X11, port 6901)            │  │
│  │  ├─ XFCE4 (desktop environment)                   │  │
│  │  ├─ Signal Desktop (Electron app)                 │  │
│  │  ├─ Audio services (PulseAudio, FFmpeg)           │  │
│  │  └─ Kasm services (upload, gamepad, printer)      │  │
│  └───────────────────────────────────────────────────┘  │
│                          │                              │
│                          ├─ Mounts PVC                  │
│                          ↓                              │
│  ┌───────────────────────────────────────────────────┐  │
│  │  PersistentVolumeClaim: signal-data-ghostwire-0   │  │
│  │  └─ /home/kasm-user/.config/Signal (messages DB)  │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Process Architecture

See [docs/container-architecture.md](../../docs/container-architecture.md) for detailed process tree, startup sequence, and 50+ running processes.

**Key processes**:
- **PID 1**: `vnc_startup.sh` (init)
- **PID 72**: Xvnc (VNC server, 81MB RAM)
- **PID 89**: XFCE4 session (80MB RAM)
- **PID 148**: Signal Desktop (383MB RAM)
- **Total**: ~1.2GB memory typical usage

### Data Persistence

**Critical paths** (must persist):
- `/home/kasm-user/.config/Signal/` - All Signal data
  - `IndexedDB/` - Message database
  - `blob_storage/` - Attachments
  - `config.json` - Device keys
  - `sql/` - Encrypted databases

**Ephemeral paths**:
- `/tmp/staticx-*/` - Service binaries (extracted at runtime)
- `/tmp/*.socket` - Unix sockets (recreated on start)

---

## Security Best Practices

### Cloud-Native Security Stack

**✅ Recommended** (infrastructure-level):
```yaml
# 1. TLS at ingress
cert-manager.io/cluster-issuer: letsencrypt-prod

# 2. Authentication at ingress
nginx.ingress.kubernetes.io/auth-url: "https://oauth2.../oauth2/auth"

# 3. Network policies
kind: NetworkPolicy  # Restrict pod-to-pod traffic

# 4. Service mesh (optional)
linkerd.io/inject: enabled  # mTLS between services

# 5. Pod security
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
```

**❌ Avoid** (application-level):
```yaml
# Don't duplicate security at app level
auth:
  enabled: true  # ← Ingress handles this

tls:
  mode: custom  # ← Ingress handles this
```

### Additional Hardening

1. **Enable Network Policies**:
   ```bash
   kubectl label namespace ghostwire name=ghostwire
   kubectl apply -f network-policy.yaml
   ```

2. **Use Pod Security Standards**:
   ```bash
   kubectl label namespace ghostwire pod-security.kubernetes.io/enforce=restricted
   ```

3. **Enable audit logging** (ingress level):
   ```yaml
   nginx.ingress.kubernetes.io/enable-access-log: "true"
   ```

4. **Set resource limits** (prevent DoS):
   ```yaml
   resources:
     limits:
       memory: 2Gi
       cpu: 1500m
   ```

---

## Comparison: Ghostwire vs Alternatives

| Feature | Ghostwire | Traditional VNC | Docker Compose | VM |
|---------|-----------|-----------------|----------------|-----|
| **Security Model** | Infrastructure (OAuth2, ingress) | App-level (VNC password) | None | OS-level |
| **Certificate Management** | Automated (cert-manager) | Manual injection | Self-signed | Manual |
| **Single Sign-On** | ✅ Yes (OIDC/OAuth2) | ❌ No | ❌ No | ❌ No |
| **Persistent Storage** | ✅ PVC (Kubernetes-native) | Manual volumes | Docker volumes | Disk images |
| **Scaling** | ✅ Declarative (YAML) | Manual | docker-compose up -d | Clone VMs |
| **Observability** | ✅ Centralized (ingress logs) | Per-app logs | Docker logs | Syslog |
| **Upgrade Strategy** | ✅ Helm rollback | Recreate container | Down/up | Snapshot restore |
| **Resource Limits** | ✅ Kubernetes limits | cgroups (manual) | Docker limits | Hypervisor |
| **Network Policies** | ✅ Native | iptables (manual) | Docker networks | Firewall rules |
| **GitOps Ready** | ✅ Flux/ArgoCD | ❌ No | ❌ No | ❌ No |

---

## Uninstallation

```bash
# Remove the Helm release
helm uninstall ghostwire -n ghostwire

# (Optional) Delete the PVC - WARNING: This deletes all Signal data!
kubectl delete pvc -n ghostwire signal-data-ghostwire-0

# (Optional) Delete the namespace
kubectl delete namespace ghostwire
```

**To preserve data**: Don't delete the PVC. You can reinstall Ghostwire later and it will reattach to the existing volume.

---

## Documentation

- **[Container Architecture](../../docs/container-architecture.md)** - Deep dive into process tree, startup sequence, network services
- **[Deployment Strategies](../../docs/deployment-strategies.md)** - Why StatefulSet, why not Flagger, rollout strategies
- **[values.yaml](values.yaml)** - Full configuration reference

---

## Contributing

Issues and pull requests welcome at: https://github.com/drengskapur/ghostwire

---

## License

- **This Helm chart**: MIT License
- **Signal Desktop**: AGPLv3
- **KasmVNC**: GPLv2

---

## Acknowledgments

Built with:
- [Signal Desktop](https://github.com/signalapp/Signal-Desktop) - Secure messaging application
- [KasmVNC](https://github.com/kasmtech/KasmVNC) - Modern VNC server with web client
- [XFCE](https://xfce.org/) - Lightweight desktop environment
