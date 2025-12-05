# Deployment Strategies

Ghostwire uses a StatefulSet to run Signal Desktop. This design choice has implications for how updates work and why certain deployment patterns don't apply.

## Why StatefulSet

Signal Desktop is a stateful application tied to a single phone number. The StatefulSet provides:

**Stable pod identity**: The pod is always named `ghostwire-0`, making debugging and log analysis predictable.

**Ordered operations**: During updates, the existing pod terminates fully before the replacement starts. This prevents two pods from competing for the same resources.

**Persistent storage binding**: The PVC automatically rebinds to the pod after restarts. Your Signal data follows the pod.

## Update Process

When you upgrade the Helm release (new image tag, configuration change):

1. Helm updates the StatefulSet spec
2. The StatefulSet controller terminates `ghostwire-0` with graceful shutdown
3. After termination completes, a new pod starts with the updated configuration
4. The new pod mounts the same PVC—all your data persists
5. Once the pod passes readiness checks, the Service routes traffic to it

**Expected downtime**: 30-90 seconds during pod replacement.

## Why Canary Deployments Don't Work

Tools like Flagger require running multiple replicas simultaneously, splitting traffic between old and new versions. This doesn't work for Ghostwire because:

**Single PVC with ReadWriteOnce**: The persistent volume can only attach to one pod at a time. A canary pod would be stuck in `Pending` waiting for the volume.

**SQLite concurrency**: Even with ReadWriteMany storage, Signal Desktop uses SQLite which doesn't support concurrent writers. Two pods accessing the same database would cause corruption.

**Single user session**: Signal Desktop is tied to one phone number with one VNC session. There's no concept of "traffic splitting"—you're either connected or not.

## Rolling Update Configuration

The StatefulSet uses rolling updates by default:

```yaml
spec:
  updateStrategy:
    type: RollingUpdate
```

This means updates happen one pod at a time (which for Ghostwire is just one pod). The replacement pod must pass readiness checks before the update is considered complete.

## Rollback

If an upgrade fails, Helm provides automatic rollback:

```bash
# Rollback to previous release
helm rollback ghostwire -n ghostwire

# Rollback to specific revision
helm rollback ghostwire 3 -n ghostwire
```

With Flux CD, configure automatic rollback on test failure:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
spec:
  test:
    enable: true
  upgrade:
    remediation:
      retries: 3
      remediateLastFailure: true
```

## Blue/Green (Manual)

For zero-downtime updates where you need full validation before switching:

1. Deploy a new release in a separate namespace (`ghostwire-green`)
2. Test the green deployment manually
3. Update the ingress to point to the green service
4. After validation, delete the blue deployment

The downside is that each deployment has its own PVC—you can't easily share Signal data between them without a migration step.

```bash
# Deploy green version
helm install ghostwire-green oci://ghcr.io/drengskapur/charts/ghostwire \
  --create-namespace -n ghostwire-green

# Test it
kubectl port-forward -n ghostwire-green svc/ghostwire 6902:6901

# Switch ingress (example for nginx)
kubectl patch ingress ghostwire -n ghostwire \
  --patch '{"spec":{"rules":[{"http":{"paths":[{"backend":{"service":{"name":"ghostwire-green","namespace":"ghostwire-green"}}}]}}]}}'

# After validation, remove blue
helm uninstall ghostwire -n ghostwire
```

## Recommended Approach

For Ghostwire's use case, the standard StatefulSet rolling update is the right choice:

- Simple and reliable
- Data integrity guaranteed by single-pod access
- Helm and Flux provide rollback mechanisms
- Brief downtime (30-90 seconds) is acceptable for a personal desktop application

Accept the tradeoff: comprehensive testing validates changes before rollout, and automatic rollback handles failures. Progressive delivery patterns designed for stateless microservices don't fit this architecture.
