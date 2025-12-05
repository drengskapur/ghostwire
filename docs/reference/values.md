---
title: Helm Values Reference - Ghostwire Configuration
description: Complete Helm values reference for Ghostwire. All configuration options for image, persistence, resources, authentication, TLS, probes, and security contexts.
---

# Helm Values Reference

Complete reference for Ghostwire Helm chart values.

## Global

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `nameOverride` | string | `""` | Override chart name |
| `fullnameOverride` | string | `""` | Override fully qualified app name |
| `global.imagePullSecrets` | list | `[]` | Global Docker registry secret names |

## Image

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `image.repository` | string | `kasmweb/signal` | Container image repository |
| `image.tag` | string | `1.18.0-rolling-daily` | Image tag |
| `image.digest` | string | `""` | Image digest (takes precedence over tag) |
| `image.pullPolicy` | string | `Always` | Image pull policy |
| `imagePullSecrets` | list | `[]` | Pod-level image pull secrets |

## Deployment

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `replicaCount` | int | `1` | Number of replicas (must be 1) |

## Service

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `service.type` | string | `ClusterIP` | Service type |
| `service.port` | int | `6901` | Service port |
| `service.targetPort` | int | `6901` | Container target port |
| `service.loadBalancerIP` | string | `""` | LoadBalancer IP (if type: LoadBalancer) |

## Persistence

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `persistence.enabled` | bool | `true` | Enable persistent storage |
| `persistence.storageClass` | string | `""` | Storage class (empty = default) |
| `persistence.accessMode` | string | `ReadWriteOnce` | PVC access mode |
| `persistence.size` | string | `10Gi` | PVC size |
| `persistence.mountPath` | string | `/home/kasm-user` | Mount path in container |

## Resources

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `resources.requests.memory` | string | `1Gi` | Memory request |
| `resources.requests.cpu` | string | `500m` | CPU request |
| `resources.limits.memory` | string | `4Gi` | Memory limit |
| `resources.limits.cpu` | string | `2000m` | CPU limit |

## Authentication

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `auth.enabled` | bool | `false` | Enable VNC password authentication |
| `auth.password` | string | `"CorrectHorseBatteryStaple"` | VNC password (change for production) |

The VNC username is always `kasm_user` (hardcoded in the Kasm image).

## TLS

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `tls.mode` | string | `disabled` | TLS mode: `auto`, `custom`, or `disabled` |
| `tls.secretName` | string | `""` | Existing secret with TLS cert/key |
| `tls.cert` | string | `""` | Inline TLS certificate (PEM) |
| `tls.key` | string | `""` | Inline TLS private key (PEM) |

TLS modes:

- `auto` — KasmVNC uses built-in self-signed certificate
- `custom` — Use certificate from secret or inline values
- `disabled` — HTTP only (use when TLS terminates at ingress)

## Display

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `display.resolution` | string | `1280x720` | VNC screen resolution |
| `shmSize` | int | `512` | Shared memory size in MB |

## Probes

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `livenessProbe.enabled` | bool | `true` | Enable liveness probe |
| `livenessProbe.tcpSocket.port` | int | `6901` | Liveness probe port |
| `livenessProbe.initialDelaySeconds` | int | `15` | Liveness initial delay |
| `livenessProbe.periodSeconds` | int | `20` | Liveness check period |
| `livenessProbe.timeoutSeconds` | int | `3` | Liveness timeout |
| `livenessProbe.failureThreshold` | int | `3` | Liveness failure threshold |
| `readinessProbe.enabled` | bool | `true` | Enable readiness probe |
| `readinessProbe.tcpSocket.port` | int | `6901` | Readiness probe port |
| `readinessProbe.initialDelaySeconds` | int | `5` | Readiness initial delay |
| `readinessProbe.periodSeconds` | int | `5` | Readiness check period |
| `readinessProbe.timeoutSeconds` | int | `2` | Readiness timeout |
| `readinessProbe.failureThreshold` | int | `3` | Readiness failure threshold |

## Security Context

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `securityContext.runAsNonRoot` | bool | `true` | Run as non-root user |
| `securityContext.runAsUser` | int | `1000` | User ID |
| `securityContext.runAsGroup` | int | `1000` | Group ID |
| `securityContext.fsGroup` | int | `1000` | Filesystem group ID |
| `securityContext.seccompProfile.type` | string | `RuntimeDefault` | Seccomp profile |
| `containerSecurityContext.allowPrivilegeEscalation` | bool | `false` | Prevent privilege escalation |
| `containerSecurityContext.capabilities.drop` | list | `[ALL]` | Dropped capabilities |
| `containerSecurityContext.readOnlyRootFilesystem` | bool | `false` | Read-only root (disabled for Kasm) |

## Node Selection

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `nodeSelector` | object | `{}` | Node selector labels |
| `tolerations` | list | `[]` | Pod tolerations |
| `affinity` | object | `{}` | Pod affinity rules |

## Environment

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `env` | list | `[]` | Additional environment variables |
| `envFrom` | list | `[]` | Environment from secrets/configmaps |

Example:

```yaml
env:
  - name: TZ
    value: "America/Los_Angeles"

envFrom:
  - secretRef:
      name: signal-secrets
```

## Pod Configuration

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `podAnnotations` | object | `{}` | Annotations for pods |
| `podLabels` | object | `{}` | Extra labels for pods |

Example:

```yaml
podAnnotations:
  linkerd.io/inject: enabled
```

## Service Account

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `serviceAccount.create` | bool | `false` | Create service account |
| `serviceAccount.name` | string | `""` | Service account name |
| `serviceAccount.annotations` | object | `{}` | Service account annotations |

## Example Values Files

### Minimal Production

```yaml
image:
  tag: "1.18.0"
  pullPolicy: IfNotPresent

persistence:
  size: 20Gi

resources:
  limits:
    memory: 6Gi
```

### With OAuth2 Annotations

```yaml
image:
  tag: "1.18.0"
  pullPolicy: IfNotPresent

persistence:
  size: 20Gi
  storageClass: ssd-retain

resources:
  limits:
    memory: 6Gi
    cpu: 4

podAnnotations:
  prometheus.io/scrape: "true"

env:
  - name: TZ
    value: "UTC"
```

### Air-Gapped Environment

```yaml
image:
  repository: registry.internal/ghostwire/signal
  tag: "1.18.0"
  pullPolicy: IfNotPresent

imagePullSecrets:
  - name: registry-credentials

persistence:
  storageClass: local-path
  size: 50Gi

resources:
  limits:
    memory: 8Gi
```

## JSON Schema

The chart includes `values.schema.json` for IDE autocompletion and validation. Compatible editors will provide inline documentation and error highlighting for invalid values.
