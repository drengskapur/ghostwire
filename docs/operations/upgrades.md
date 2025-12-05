# Upgrades

Upgrading Ghostwire involves updating the Helm release. This guide covers upgrade procedures and rollback strategies.

## Upgrade Process

### Check Current Version

```bash
helm list -n ghostwire
```

### List Available Versions

```bash
# OCI registry
skopeo list-tags docker://ghcr.io/drengskapur/charts/ghostwire

# Or check GitHub releases
gh release list -R drengskapur/ghostwire
```

### Upgrade

```bash
helm upgrade ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  --version <new-version> \
  -n ghostwire
```

Keep your custom values:

```bash
helm upgrade ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  --version <new-version> \
  -f values-production.yaml \
  -n ghostwire
```

## What Happens During Upgrade

1. Helm compares the new manifest with the current state
2. The StatefulSet spec is updated
3. The existing pod (`ghostwire-0`) terminates gracefully
4. A new pod starts with the updated configuration
5. The pod mounts the same PVC—your data persists
6. Readiness probes confirm the pod is healthy

**Expected downtime**: 30-90 seconds while the pod restarts.

## Pre-Upgrade Checklist

1. **Backup your data**

```bash
# Create a snapshot if your storage class supports it
kubectl get pvc -n ghostwire -o jsonpath='{.items[0].spec.volumeName}'
# Use your cloud provider's snapshot API
```

2. **Review the changelog**

Check the release notes for breaking changes:

```bash
gh release view <version> -R drengskapur/ghostwire
```

3. **Test in a staging environment** (if available)

## Rollback

If the upgrade fails or introduces issues:

```bash
# Rollback to previous release
helm rollback ghostwire -n ghostwire

# Rollback to specific revision
helm history ghostwire -n ghostwire
helm rollback ghostwire <revision> -n ghostwire
```

### Automatic Rollback with Flux CD

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: ghostwire
  namespace: ghostwire
spec:
  chart:
    spec:
      chart: oci://ghcr.io/drengskapur/charts/ghostwire
      version: ">=1.0.0"
  test:
    enable: true
  upgrade:
    remediation:
      retries: 3
      remediateLastFailure: true
```

Flux will run Helm tests after upgrade and rollback if they fail.

## Image Updates

The container image may update more frequently than the chart. To update just the image:

```bash
helm upgrade ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  --set image.tag=1.19.0-rolling-daily \
  -n ghostwire
```

### Image Tag Strategies

**Pinned version** (recommended for production):

```yaml
image:
  tag: "1.18.0"
  pullPolicy: IfNotPresent
```

**Rolling tag** (latest within minor version):

```yaml
image:
  tag: "1.18.0-rolling-daily"
  pullPolicy: Always
```

Rolling tags get updates automatically but may introduce unexpected changes.

## Breaking Changes

### Detecting Breaking Changes

Check the changelog for:
- Major version bumps (1.x → 2.x)
- Notes about "breaking changes" or "migration required"
- Changes to default values
- Removed or renamed values

### Common Breaking Changes

**Renamed values**: Helm will error if you pass unknown values. Update your values file.

**Changed defaults**: Review the diff between your values and new defaults:

```bash
helm show values oci://ghcr.io/drengskapur/charts/ghostwire --version <new> > new-defaults.yaml
helm show values oci://ghcr.io/drengskapur/charts/ghostwire --version <old> > old-defaults.yaml
diff old-defaults.yaml new-defaults.yaml
```

**Schema changes**: The chart includes a JSON schema. Validate your values:

```bash
helm template ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  -f values-production.yaml \
  --version <new>
```

## Signal Desktop Updates

Signal Desktop updates are delivered through the container image, not the Helm chart. Kasm rebuilds images when new Signal Desktop versions are released.

To get the latest Signal Desktop:
1. Pull the latest image tag
2. Restart the pod

```bash
kubectl rollout restart statefulset ghostwire -n ghostwire
```

Signal Desktop also has in-app update notifications, but those may not work in the container environment depending on permissions.

## Maintenance Windows

For production deployments, schedule upgrades during low-usage periods:

- The pod restarts, terminating any active VNC session
- Users will need to reconnect after the upgrade
- Message delivery continues through Signal servers during the brief downtime

Communicate planned maintenance to users if the service is shared.
