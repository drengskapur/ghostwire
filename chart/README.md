<!--- app-name: Ghostwire -->

# Ghostwire

Ghostwire provides a cloud-native Signal Desktop deployment for Kubernetes with browser-based VNC access, persistent storage, and infrastructure-level security. Unlike traditional VNC deployments that bake authentication and TLS into the application, Ghostwire integrates with your existing Kubernetes security stack (OAuth2, cert-manager, ingress controllers, service mesh).

[Overview of Ghostwire](https://github.com/drengskapur/ghostwire)

## TL;DR

```bash
helm install my-ghostwire oci://ghcr.io/drengskapur/charts/ghostwire --version 0.0.0-latest-stable
```

**Disclaimer:** This chart is not affiliated with or endorsed by Signal Messenger LLC or Kasm Technologies Inc. Signal is a registered trademark of Signal Messenger LLC. This is a community-maintained deployment solution.

## Introduction

Ghostwire deploys Signal Desktop in a Kubernetes-native way using:

- **KasmVNC** for browser-based VNC access (no client needed)
- **StatefulSet + PVC** for persistent Signal data across pod restarts
- **Cloud-native security** via infrastructure (OAuth2, cert-manager, network policies) instead of application-level auth
- **XFCE4 desktop** running Signal Desktop in an isolated container

This approach allows Signal Desktop to run as a first-class Kubernetes workload with standard observability, security, and operational patterns.

## Prerequisites

- Kubernetes 1.25+
- Helm 3.8.0+
- PV provisioner support in the underlying infrastructure (for persistent Signal data)

**Optional (for production):**

- Ingress controller (nginx, Traefik, etc.) for HTTPS access
- cert-manager for automatic TLS certificate management
- OAuth2-proxy or similar for authentication

## Installing the Chart

To install the chart with the release name `my-ghostwire`:

```bash
helm install my-ghostwire oci://ghcr.io/drengskapur/charts/ghostwire --version 0.0.0-latest-stable
```

The command deploys Ghostwire on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Quick Start

### Development (port-forward)

```bash
# Install
helm install ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  --version 0.0.0-latest-stable \
  --create-namespace \
  -n ghostwire

# Access
kubectl port-forward -n ghostwire svc/ghostwire 6901:6901
```

Open in browser: `http://localhost:6901?keyboard=1`

### Production (with OAuth2 + cert-manager)

See [Production Setup](#production-setup) for ingress configuration with TLS and authentication.

## Configuration and Installation Details

### Cloud-Native Security Architecture

**Ghostwire's Philosophy:** Security is handled by Kubernetes infrastructure, not the application.

**Traditional VNC deployments:**

- VNC password authentication (credential management burden)
- Self-signed certificates (browser warnings)
- Per-app TLS configuration (certificate gymnastics)
- Fragmented logs and metrics

**Ghostwire's cloud-native approach:**

- Authentication at ingress (OAuth2-proxy, Dex, Keycloak)
- TLS at ingress (cert-manager + Let's Encrypt)
- Network isolation (NetworkPolicy, service mesh)
- Centralized observability (all auth logs in ingress)

This results in:

- ✅ Single sign-on across all applications
- ✅ Automatic certificate rotation
- ✅ Consistent security policies
- ✅ Standard Kubernetes tooling

### Production Setup

This is the **recommended way** to run Ghostwire in production.

#### Architecture

```text
Internet → Ingress (TLS + OAuth2) → ClusterIP Service → Ghostwire Pod
           ↓                          ↓
     cert-manager              Network Policy
     Let's Encrypt             (optional isolation)
     OAuth2-proxy
```

#### Step 1: Install Ghostwire

```bash
helm install ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  --set auth.enabled=false \
  --set tls.mode=disabled \
  --set service.type=ClusterIP \
  --set persistence.size=15Gi \
  -n ghostwire
```

#### Step 2: Deploy Ingress with TLS + OAuth2

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

#### Step 3: (Optional) Add Network Policy

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

### Ingress

This chart provides support for Ingress resources. If you have an ingress controller installed on your cluster, such as nginx-ingress-controller or Traefik, you can expose Ghostwire via ingress.

**Important:** For VNC/WebSocket support, ensure your ingress controller has the following annotations:

```yaml
nginx.ingress.kubernetes.io/websocket-services: "ghostwire"
nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
```

### TLS/SSL Support

Ghostwire supports three TLS modes via the `tls.mode` parameter:

1. **`disabled`** (default, recommended): TLS handled at ingress via cert-manager
2. **`auto`**: KasmVNC uses built-in self-signed certificate (browser warnings)
3. **`custom`**: Provide your own TLS certificate via `tls.secretName` or inline `tls.cert`/`tls.key`

**Production recommendation:** Use `tls.mode=disabled` and handle TLS at the ingress level with cert-manager.

Example with custom certificate:

```bash
# Create secret with your certificate
kubectl create secret tls ghostwire-tls \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key \
  -n ghostwire

# Install with custom cert
helm install ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  --set tls.mode=custom \
  --set tls.secretName=ghostwire-tls \
  -n ghostwire
```

### Authentication

VNC authentication can be enabled via the `auth.enabled` and `auth.password` parameters.

**Production recommendation:** Leave `auth.enabled=false` and use OAuth2-proxy at the ingress level for enterprise SSO.

Example with built-in VNC auth (development only):

```bash
helm install ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  --set auth.enabled=true \
  --set auth.password=mySecurePassword \
  -n ghostwire
```

### Persistent Storage

The chart stores Signal Desktop data in a PersistentVolume at `/home/kasm-user/.config/Signal/`. This includes:

- Message database (IndexedDB)
- Attachments (blob_storage)
- Device keys (config.json)
- Encrypted databases (sql/)

**Important:** Signal data is tied to a device registration. Deleting the PVC will unlink your device.

To use a specific StorageClass:

```yaml
persistence:
  enabled: true
  size: 15Gi
  storageClass: fast-ssd  # Use your cluster's SSD storage class
```

If you encounter errors when working with persistent volumes, refer to the [Kubernetes documentation on troubleshooting PVs](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#troubleshooting).

### Additional Environment Variables

In case you want to add extra environment variables (useful for custom configurations), you can use the `env` property:

```yaml
env:
  - name: VNC_RESOLUTION
    value: "1920x1080"
  - name: CUSTOM_VAR
    value: "custom_value"
```

Alternatively, you can use a ConfigMap or a Secret with the environment variables using `envFrom`:

```yaml
envFrom:
  - configMapRef:
      name: ghostwire-config
  - secretRef:
      name: ghostwire-secrets
```

### Pod Affinity

This chart allows you to set your custom affinity using the `affinity` parameter. Find more information about Pod affinity in the [Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity).

Example:

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/arch
          operator: In
          values:
          - amd64
```

### Resource Limits

It is strongly recommended to set resource limits for production deployments to prevent resource exhaustion:

```yaml
resources:
  requests:
    memory: 1Gi
    cpu: 500m
  limits:
    memory: 4Gi
    cpu: 2000m
```

Signal Desktop (Electron) can be memory-intensive, especially with large conversation histories. Monitor actual usage and adjust accordingly.

## Persistence

The [KasmVNC Signal Desktop image](https://github.com/kasmtech/workspaces-images) stores Signal data at the `/home/kasm-user/.config/Signal/` path of the container. Persistent Volume Claims are used to keep the data across deployments.

**StatefulSet behavior:**

- Each replica gets its own PVC (named `signal-data-<release>-<ordinal>`)
- Signal Desktop is tied to a phone number, so `replicaCount: 1` is enforced
- Deleting the StatefulSet does NOT delete the PVC by default

If you need to completely reset Signal data:

```bash
# Delete the release
helm uninstall ghostwire -n ghostwire

# Delete the PVC (WARNING: This removes all Signal data!)
kubectl delete pvc -n ghostwire signal-data-ghostwire-0

# Reinstall
helm install ghostwire oci://ghcr.io/drengskapur/charts/ghostwire -n ghostwire
```

## Parameters

### Global Parameters

| Name                      | Description                                     | Value |
| ------------------------- | ----------------------------------------------- | ----- |
| `global.imagePullSecrets` | Global Docker registry secret names as an array | `[]`  |
| `nameOverride`            | Override chart name                             | `""`  |
| `fullnameOverride`        | Override fully qualified app name               | `""`  |

### Image Parameters

| Name               | Description                                | Value                          |
| ------------------ | ------------------------------------------ | ------------------------------ |
| `image.repository` | Signal Desktop image repository            | `kasmweb/signal`               |
| `image.tag`        | Signal Desktop image tag                   | `1.18.0-rolling-daily`         |
| `image.pullPolicy` | Image pull policy                          | `Always`                       |
| `imagePullSecrets` | Docker registry secret names as an array   | `[]`                           |

### Deployment Parameters

| Name           | Description                               | Value |
| -------------- | ----------------------------------------- | ----- |
| `replicaCount` | Number of replicas (must be 1 for Signal) | `1`   |

### Service Parameters

| Name                    | Description                                        | Value       |
| ----------------------- | -------------------------------------------------- | ----------- |
| `service.type`          | Kubernetes Service type                            | `ClusterIP` |
| `service.port`          | Service port for VNC access                        | `6901`      |
| `service.targetPort`    | Container target port for VNC                      | `6901`      |
| `service.loadBalancerIP`| LoadBalancer IP (for type: LoadBalancer)           | `""`        |

### Persistence Parameters

| Name                       | Description                                   | Value             |
| -------------------------- | --------------------------------------------- | ----------------- |
| `persistence.enabled`      | Enable persistent storage                     | `true`            |
| `persistence.storageClass` | PVC Storage Class                             | `""`              |
| `persistence.accessMode`   | PVC Access Mode                               | `ReadWriteOnce`   |
| `persistence.size`         | PVC Storage Request size                      | `10Gi`            |
| `persistence.mountPath`    | Container mount path for Signal data          | `/home/kasm-user` |

### Resource Parameters

| Name                        | Description          | Value    |
| --------------------------- | -------------------- | -------- |
| `resources.limits.cpu`      | CPU limit            | `2000m`  |
| `resources.limits.memory`   | Memory limit         | `4Gi`    |
| `resources.requests.cpu`    | CPU request          | `500m`   |
| `resources.requests.memory` | Memory request       | `1Gi`    |

### Security Parameters

| Name                                          | Description                          | Value             |
| --------------------------------------------- | ------------------------------------ | ----------------- |
| `securityContext.runAsUser`                   | User ID to run the container         | `1000`            |
| `securityContext.runAsGroup`                  | Group ID to run the container        | `1000`            |
| `securityContext.fsGroup`                     | Filesystem group ID for volumes      | `1000`            |
| `securityContext.runAsNonRoot`                | Ensure container runs as non-root    | `true`            |
| `securityContext.seccompProfile.type`         | Seccomp profile configuration        | `RuntimeDefault`  |
| `containerSecurityContext.allowPrivilegeEscalation` | Prevent privilege escalation   | `false`           |
| `containerSecurityContext.capabilities.drop`  | Dropped capabilities                 | `["ALL"]`         |
| `containerSecurityContext.readOnlyRootFilesystem` | Read-only root filesystem        | `false`           |

### Authentication Parameters

| Name            | Description                           | Value                        |
| --------------- | ------------------------------------- | ---------------------------- |
| `auth.enabled`  | Enable VNC password authentication    | `false`                      |
| `auth.password` | VNC authentication password           | `CorrectHorseBatteryStaple`  |

### TLS Parameters

| Name             | Description                                                    | Value      |
| ---------------- | -------------------------------------------------------------- | ---------- |
| `tls.mode`       | TLS mode: auto, custom, or disabled                            | `disabled` |
| `tls.secretName` | Name of existing Kubernetes secret containing TLS cert/key     | `""`       |
| `tls.cert`       | TLS certificate (PEM format, inline)                           | `""`       |
| `tls.key`        | TLS private key (PEM format, inline)                           | `""`       |

### Display Parameters

| Name                 | Description           | Value       |
| -------------------- | --------------------- | ----------- |
| `display.resolution` | VNC screen resolution | `1280x720`  |

### Environment Variables

| Name      | Description                              | Value |
| --------- | ---------------------------------------- | ----- |
| `env`     | Array of additional environment variables| `[]`  |
| `envFrom` | Additional environment from secrets/configmaps | `[]` |
| `shmSize` | Shared memory size in MB                 | `512` |

### Pod Parameters

| Name              | Description                          | Value |
| ----------------- | ------------------------------------ | ----- |
| `podAnnotations`  | Annotations for pods                 | `{}`  |
| `podLabels`       | Extra labels for pods                | `{}`  |
| `nodeSelector`    | Node labels for pod assignment       | `{}`  |
| `tolerations`     | Tolerations for pod assignment       | `[]`  |
| `affinity`        | Affinity rules for pod assignment    | `{}`  |

### Service Account Parameters

| Name                         | Description               | Value   |
| ---------------------------- | ------------------------- | ------- |
| `serviceAccount.create`      | Create service account    | `false` |
| `serviceAccount.annotations` | Service account annotations | `{}`  |
| `serviceAccount.name`        | Service account name      | `""`    |

### Health Probe Parameters

| Name                                  | Description                  | Value   |
| ------------------------------------- | ---------------------------- | ------- |
| `livenessProbe.enabled`               | Enable liveness probe        | `true`  |
| `livenessProbe.initialDelaySeconds`   | Initial delay seconds        | `15`    |
| `livenessProbe.periodSeconds`         | Period seconds               | `20`    |
| `livenessProbe.timeoutSeconds`        | Timeout seconds              | `3`     |
| `livenessProbe.failureThreshold`      | Failure threshold            | `3`     |
| `readinessProbe.enabled`              | Enable readiness probe       | `true`  |
| `readinessProbe.initialDelaySeconds`  | Initial delay seconds        | `5`     |
| `readinessProbe.periodSeconds`        | Period seconds               | `5`     |
| `readinessProbe.timeoutSeconds`       | Timeout seconds              | `2`     |
| `readinessProbe.failureThreshold`     | Failure threshold            | `3`     |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```bash
helm install my-ghostwire \
  --set auth.enabled=true \
  --set auth.password=mySecurePassword \
  --set persistence.size=20Gi \
    oci://ghcr.io/drengskapur/charts/ghostwire
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

```bash
helm install my-ghostwire -f values.yaml oci://ghcr.io/drengskapur/charts/ghostwire
```

> **Tip**: You can use the default [values.yaml](https://github.com/drengskapur/ghostwire/blob/main/chart/values.yaml)

## Troubleshooting

### Signal Desktop Won't Start

Check pod logs:

```bash
kubectl logs -n ghostwire ghostwire-0 | grep -E "(ERROR|signal-desktop)"
```

Common issues:

- Insufficient memory → Increase `resources.limits.memory`
- GPU initialization errors → Expected (falls back to software rendering)
- D-Bus errors → Expected (only session bus needed)

### VNC Shows Blank Screen

1. Verify pod is running:

   ```bash
   kubectl get pod -n ghostwire ghostwire-0
   ```

2. Check resource usage:

   ```bash
   kubectl top pod -n ghostwire ghostwire-0
   ```

3. Increase shared memory if browser crashes:

   ```bash
   helm upgrade ghostwire oci://ghcr.io/drengskapur/charts/ghostwire --set shmSize=1024 --reuse-values
   ```

### WebSocket Connection Fails (Ingress)

Verify ingress annotations for WebSocket support:

```bash
kubectl get ingress -n ghostwire ghostwire -o yaml
```

Required for NGINX ingress:

```yaml
nginx.ingress.kubernetes.io/websocket-services: "ghostwire"
nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
```

### Persistent Data Loss

Check PVC status:

```bash
kubectl get pvc -n ghostwire
kubectl describe pvc -n ghostwire signal-data-ghostwire-0
```

Common causes:

- PVC not bound → Check StorageClass availability
- Pod deleted with PVC → Verify `helm uninstall` didn't delete PVC
- Node failure → Check PV access mode and node availability

## Upgrading

### To 1.x.x

No breaking changes from initial release.

## License

Copyright &copy; 2025 drengskapur

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

---

## Acknowledgments

This project uses the following open-source software:

- **[Signal Desktop](https://github.com/signalapp/Signal-Desktop)** - Secure messaging application (AGPLv3)
  - "Signal" is a registered trademark of Signal Messenger LLC
- **[Kasm Workspaces](https://github.com/kasmtech/workspaces-images)** - Container streaming platform with VNC (MIT License)
  - Provides the kasmweb/signal Docker image
  - Copyright 2022 Kasm Technologies Inc
- **[KasmVNC](https://github.com/kasmtech/KasmVNC)** - Modern VNC server with web client
- **[XFCE](https://xfce.org/)** - Lightweight desktop environment

Signal Messenger LLC and Kasm Technologies Inc do not endorse or support this project.
