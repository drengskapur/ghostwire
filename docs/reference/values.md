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
| `resources.requests.memory` | string | `2Gi` | Memory request |
| `resources.requests.cpu` | string | `500m` | CPU request |
| `resources.limits.memory` | string | `4Gi` | Memory limit |
| `resources.limits.cpu` | string | `2` | CPU limit |

## Probes

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `livenessProbe.tcpSocket.port` | int | `6901` | Liveness probe port |
| `livenessProbe.initialDelaySeconds` | int | `60` | Liveness initial delay |
| `livenessProbe.periodSeconds` | int | `30` | Liveness check period |
| `livenessProbe.failureThreshold` | int | `3` | Liveness failure threshold |
| `readinessProbe.tcpSocket.port` | int | `6901` | Readiness probe port |
| `readinessProbe.initialDelaySeconds` | int | `30` | Readiness initial delay |
| `readinessProbe.periodSeconds` | int | `10` | Readiness check period |
| `readinessProbe.failureThreshold` | int | `5` | Readiness failure threshold |

## Security Context

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `securityContext.runAsNonRoot` | bool | `true` | Run as non-root user |
| `securityContext.runAsUser` | int | `1000` | User ID |
| `securityContext.runAsGroup` | int | `1000` | Group ID |

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

Example:

```yaml
env:
  - name: TZ
    value: "America/Los_Angeles"
  - name: VNC_RESOLUTION
    value: "1920x1080"
```

## Pod Annotations

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `podAnnotations` | object | `{}` | Annotations for pods |

Example:

```yaml
podAnnotations:
  linkerd.io/inject: enabled
```

## Service Account

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `serviceAccount.create` | bool | `true` | Create service account |
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
