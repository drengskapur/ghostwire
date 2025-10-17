# Deployment Strategies for Ghostwire

## Overview

Ghostwire is a stateful application (Signal Desktop) that presents unique challenges for progressive delivery and canary deployments. This document explains why certain deployment strategies work or don't work for this use case.

## Current Architecture

### StatefulSet with PersistentVolumeClaim

**Implementation:**
- Single replica StatefulSet (`ghostwire-0`)
- ReadWriteOnce (RWO) PersistentVolumeClaim for Signal data
- Data stored in `/home/kasm-user` (SQLite database, encryption keys, messages, media)

**Why StatefulSet:**
1. **Stable pod identity** - `ghostwire-0` always has same name and PVC binding
2. **Ordered deployment** - Ensures single pod at a time during updates
3. **Persistent storage binding** - PVC follows the pod through restarts
4. **Data integrity** - No risk of multiple pods accessing same data simultaneously

### Image Update Process

When updating the container image (e.g., new Signal Desktop version):

1. Flux CD detects image change in HelmRelease values
2. Helm upgrade updates StatefulSet spec
3. StatefulSet controller:
   - Terminates existing `ghostwire-0` pod (graceful shutdown)
   - Waits for termination to complete
   - Creates new `ghostwire-0` pod with updated image
   - New pod mounts same PVC (Signal data persists)
4. Service automatically routes to new pod when ready

**Downtime:** ~30-90 seconds during pod replacement (depends on graceful shutdown time)

## Why Flagger/Progressive Delivery Won't Work

### Flagger Requirements

Flagger (and similar canary deployment tools) require:

1. **Multiple replicas running simultaneously**
   - Primary deployment: N replicas (old version)
   - Canary deployment: M replicas (new version)
   - Traffic shifting between them

2. **Stateless or shared-nothing architecture**
   - Each replica is independent
   - Can handle subset of traffic
   - No conflicting state

3. **Load balancing**
   - Traffic can be split (e.g., 90% primary, 10% canary)
   - Gradual shift as metrics validate canary

### Ghostwire Constraints

#### 1. Single PVC with ReadWriteOnce

**Problem:**
```yaml
# Primary pod
ghostwire-primary-abc123:
  volumeMounts:
  - name: signal-data
    mountPath: /home/kasm-user
    # PVC mounted here ✅

# Canary pod (created by Flagger)
ghostwire-canary-xyz789:
  volumeMounts:
  - name: signal-data
    mountPath: /home/kasm-user
    # ❌ Cannot mount - RWO PVC already bound to primary pod
```

**Result:** Canary pod stuck in `Pending` state with error:
```
Multi-Attach error for volume "signal-data-ghostwire-0"
Volume is already exclusively attached to one node and can't be attached to another
```

#### 2. SQLite Database Concurrency

Even with ReadWriteMany (RWX) storage (NFS, CephFS):

**Problem:**
- Signal Desktop uses SQLite for message/state storage
- SQLite doesn't support concurrent writers
- Two pods accessing same database = corruption risk

**Example failure scenario:**
```
Pod 1: BEGIN TRANSACTION; UPDATE messages SET status='read'...
Pod 2: BEGIN TRANSACTION; UPDATE messages SET status='read'...
Pod 1: COMMIT;
Pod 2: COMMIT; -- ❌ Database locked or corrupted
```

#### 3. Single User Session

Signal Desktop is not a microservice:
- Tied to one phone number/device
- Single VNC session (one user at a time)
- No concept of "traffic splitting" - you're either connected or not

**What traffic shifting would mean:**
```
10% traffic to canary → 10% of... what? VNC connections are persistent sessions
50% traffic to canary → User randomly switches between two different Signal instances?
100% traffic to canary → Just use the new version (same as StatefulSet update)
```

## Alternative Deployment Strategies

### 1. Current Approach: StatefulSet Rolling Update ✅ RECOMMENDED

**How it works:**
```yaml
apiVersion: apps/v1
kind: StatefulSet
spec:
  replicas: 1
  updateStrategy:
    type: RollingUpdate
```

**Pros:**
- ✅ Simple and reliable
- ✅ Data integrity guaranteed
- ✅ Automatic rollback via Helm
- ✅ Works with existing PVC strategy

**Cons:**
- ❌ Brief downtime during pod replacement (30-90s)
- ❌ No canary validation before full rollout
- ❌ No gradual traffic shifting

**Best for:** Current use case (single-user desktop application)

### 2. Blue/Green Deployment (Manual)

**How it works:**
1. Deploy "green" version in separate namespace (`ghostwire-green`)
2. Manually test the green deployment
3. Switch service/ingress to point to green
4. Delete blue deployment after validation

**Pros:**
- ✅ Full validation before switching
- ✅ Instant rollback (switch back to blue)
- ✅ Zero downtime if done correctly

**Cons:**
- ❌ Requires manual intervention
- ❌ Double resource usage during transition
- ❌ Separate PVC (can't easily preserve user data between versions)
- ❌ More complex to automate

**Example:**
```bash
# Deploy green version
helm install ghostwire-green ./chart -n ghostwire-green

# Test it
kubectl port-forward -n ghostwire-green svc/ghostwire-green 6901:6901

# Switch ingress/service
kubectl patch ingress ghostwire --patch '{"spec":{"rules":[{"host":"ghostwire.example.com","http":{"paths":[{"backend":{"service":{"name":"ghostwire-green"}}}]}}]}}'

# Delete blue after validation
helm uninstall ghostwire -n ghostwire
```

### 3. Recreate Strategy Deployment

**How it works:**
```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  replicas: 1
  strategy:
    type: Recreate  # Kill all old pods before creating new ones
```

**Pros:**
- ✅ Simpler than StatefulSet for some use cases
- ✅ Faster pod replacement than StatefulSet
- ✅ Works with RWO PVC

**Cons:**
- ❌ Downtime during updates (same as StatefulSet)
- ❌ No progressive delivery
- ❌ Loses StatefulSet benefits (stable identity, ordering)

**Comparison to StatefulSet:**
| Feature | StatefulSet | Deployment (Recreate) |
|---------|-------------|----------------------|
| Pod naming | `ghostwire-0` (stable) | `ghostwire-abc123` (random) |
| PVC binding | Automatic, stable | Manual volumeClaimTemplate or pre-created PVC |
| Update speed | Slower (ordered) | Faster (immediate recreate) |
| Complexity | Higher | Lower |

**Verdict:** Marginal benefits, not worth switching from StatefulSet

### 4. Argo Rollouts (Advanced)

**How it works:**
- Similar to Flagger but more flexible
- Supports "one pod at a time" strategies
- Can integrate with analysis/metrics

**Configuration:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
spec:
  replicas: 1
  strategy:
    blueGreen:
      autoPromotionEnabled: false
      scaleDownDelaySeconds: 30
```

**Pros:**
- ✅ More control over rollout process
- ✅ Can pause for manual validation
- ✅ Built-in analysis and metrics

**Cons:**
- ❌ Still can't run multiple replicas simultaneously (same PVC issue)
- ❌ Adds complexity (need Argo Rollouts controller)
- ❌ Overkill for single-replica application

**Verdict:** Not worth the added complexity for this use case

## Recommended Approach

### Keep StatefulSet + Enhanced Validation

**Strategy:**
1. Use existing StatefulSet with rolling updates
2. Enhance Helm tests to validate deployments
3. Use Flux CD health checks and automated rollback
4. Monitor with Prometheus/Grafana

**Implementation:**

#### 1. Enhanced Helm Tests (Already Implemented)

```yaml
# Test authentication
helm test ghostwire -n ghostwire

# Tests validate:
# - VNC authentication working
# - DNS resolution
# - StatefulSet pod running
# - PVC bound correctly
# - TLS configuration (if enabled)
# - Basic connectivity
```

#### 2. Flux CD Automated Rollback

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: ghostwire
spec:
  test:
    enable: true  # Run helm tests after upgrade
  install:
    remediation:
      retries: 3
  upgrade:
    remediation:
      retries: 3
      remediateLastFailure: true  # Auto-rollback on failure
  rollback:
    recreate: true
    cleanupOnFail: true
```

#### 3. Health Checks

```yaml
# In StatefulSet
livenessProbe:
  tcpSocket:
    port: 6901
  initialDelaySeconds: 60
  periodSeconds: 30
  failureThreshold: 3

readinessProbe:
  tcpSocket:
    port: 6901
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 5
```

#### 4. Monitoring (Future)

```yaml
# ServiceMonitor for Prometheus
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: ghostwire
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: ghostwire
  endpoints:
  - port: metrics
    interval: 30s
```

## Migration Path (If Needed)

If requirements change and we need true progressive delivery:

### Option A: Multi-User Architecture

**Changes required:**
1. Run multiple Ghostwire instances (each with own Signal account)
2. Add routing layer to assign users to instances
3. Use Deployment instead of StatefulSet
4. Implement Flagger for progressive rollouts

**Complexity:** High - fundamental architecture change

### Option B: Ephemeral Desktop Pattern

**Changes required:**
1. Make Signal data portable/backup-restore
2. Treat each deployment as fresh instance
3. Restore user data from external source (S3, backup PVC)
4. Allow blue/green with data migration

**Complexity:** Medium - requires backup/restore automation

## Conclusion

**For Ghostwire's current architecture (single-user stateful desktop):**

✅ **Use StatefulSet with rolling updates**
- Simple, reliable, appropriate for use case
- Enhanced with Helm tests for validation
- Flux CD provides automated rollback on failure

❌ **Don't use Flagger or canary deployments**
- Incompatible with single-replica + RWO PVC architecture
- Adds complexity without benefits
- Would require fundamental architecture changes

**Accept the tradeoff:**
- Brief downtime during updates (30-90s) is acceptable
- Data integrity and simplicity are more valuable
- Comprehensive testing validates changes before rollout

## References

- [Kubernetes StatefulSet Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Flagger Documentation](https://docs.flagger.app/)
- [Flux CD HelmRelease Spec](https://fluxcd.io/flux/components/helm/helmreleases/)
- [Persistent Volumes and Claims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
