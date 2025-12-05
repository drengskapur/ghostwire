# Configuration

Ghostwire exposes Helm values for customizing the deployment. This guide covers the most commonly adjusted settings.

## Resource Allocation

Signal Desktop needs adequate memory. The defaults work for most cases:

```yaml
resources:
  requests:
    memory: "2Gi"
    cpu: "500m"
  limits:
    memory: "4Gi"
    cpu: "2"
```

If Signal Desktop crashes or becomes unresponsive, increase the memory limit:

```bash
helm upgrade ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  --set resources.limits.memory=6Gi \
  -n ghostwire
```

## Persistence

Data persists in a PVC mounted at `/home/kasm-user`. Configure the volume size based on expected message history:

```yaml
persistence:
  enabled: true
  size: 10Gi
  accessMode: ReadWriteOnce
  # storageClass: ""  # Uses cluster default
```

For production, specify an explicit storage class:

```bash
helm upgrade ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  --set persistence.storageClass=ssd \
  --set persistence.size=20Gi \
  -n ghostwire
```

## Image Configuration

The chart uses Kasm's Signal Desktop image:

```yaml
image:
  repository: kasmweb/signal
  tag: "1.18.0-rolling-daily"
  pullPolicy: Always
```

Pin to a specific tag for reproducible deployments:

```bash
helm upgrade ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  --set image.tag=1.18.0 \
  --set image.pullPolicy=IfNotPresent \
  -n ghostwire
```

## Service Configuration

The default service type is ClusterIP on port 6901:

```yaml
service:
  type: ClusterIP
  port: 6901
  targetPort: 6901
```

For direct external access (not recommended for production):

```bash
helm upgrade ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  --set service.type=LoadBalancer \
  -n ghostwire
```

Prefer ingress with authentication for production access.

## Environment Variables

Pass environment variables to the container:

```yaml
env:
  - name: TZ
    value: "America/Los_Angeles"
```

The Kasm container supports several environment variables for VNC configuration. See the [Kasm documentation](https://kasmweb.com/docs) for details.

## Node Selection

Schedule on specific nodes:

```yaml
nodeSelector:
  kubernetes.io/os: linux

tolerations: []

affinity: {}
```

## Values File

For complex configurations, use a values file:

```yaml
# values-production.yaml
resources:
  limits:
    memory: 6Gi
    cpu: 4

persistence:
  size: 50Gi
  storageClass: ssd-retain

image:
  tag: "1.18.0"
  pullPolicy: IfNotPresent
```

Apply with:

```bash
helm upgrade ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  -f values-production.yaml \
  -n ghostwire
```

## Complete Values Reference

See [values.yaml](https://github.com/drengskapur/ghostwire/blob/main/chart/values.yaml) for all available options with documentation.

The chart includes a JSON schema for validation. IDEs with YAML schema support will provide autocomplete and validation.
