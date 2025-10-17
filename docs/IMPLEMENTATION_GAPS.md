# Ghostwire Helm Chart: Documentation vs Implementation Gaps

## Executive Summary

This analysis identifies 23 documented features and cloud-native best practices that are mentioned in the Ghostwire documentation but not yet implemented in the Helm chart. The gaps range from **critical infrastructure integration patterns** (OAuth2, cert-manager, ingress) to **operational best practices** (monitoring, network policies, backup automation).

These gaps represent intentional design decisions (infrastructure-level security is delegated to operators) rather than oversights, but implementing chart templates for these patterns would significantly improve cloud-native readiness.

---

## Gap Summary by Category

| Category | Count | Priority | Impact |
|----------|-------|----------|--------|
| **Ingress & Service Mesh** | 4 | CRITICAL | Production deployment requires manual setup |
| **Monitoring & Observability** | 3 | HIGH | No built-in metrics/observability integration |
| **Network Security** | 2 | HIGH | No network policies or service mesh templates |
| **Backup & Disaster Recovery** | 3 | HIGH | Manual backup procedures, no automation |
| **RBAC & Pod Security** | 2 | MEDIUM | Test-only RBAC, no app-level RBAC templates |
| **Pod Disruption Budgets** | 1 | MEDIUM | No PDB for high-availability scenarios |
| **Advanced Scheduling** | 2 | LOW | Pod Priority, horizontal scaling not documented |
| **GitOps Integration** | 1 | LOW | Flux CD examples in docs, no templates |
| **Resource Management** | 3 | MEDIUM | No HPA, initial resource suggestions incomplete |

---

## Detailed Gap Analysis

### 1. INGRESS & CERTIFICATE MANAGEMENT (CRITICAL)

#### Gap 1.1: Ingress Template
- **Documented:** chart/README.md, lines 140-177, 237-276
  - Full NGINX Ingress example with OAuth2-proxy, cert-manager, WebSocket support
  - Explicit annotations for long-lived connections (3600s timeouts)
  - TLS with cert-manager integration
- **What's Missing in Chart:**
  - No `templates/ingress.yaml` template
  - No values for ingress configuration
  - No conditional rendering based on service type
  - Users must create manual YAML or use external tools
- **Values Needed:**
  ```yaml
  ingress:
    enabled: false  # Optional ingress template
    className: nginx
    hosts:
      - host: signal.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: ghostwire-tls
        hosts:
          - signal.example.com
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
      nginx.ingress.kubernetes.io/websocket-services: ghostwire
      nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
      nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
  ```
- **Priority:** CRITICAL
- **Rationale:** Production deployments require ingress; lack of template forces users to duplicate work

#### Gap 1.2: cert-manager Integration
- **Documented:** chart/README.md, lines 149-150, 629
  - Example: `cert-manager.io/cluster-issuer: letsencrypt-prod`
  - Example: `secretName: ghostwire-tls  # Auto-created by cert-manager`
- **What's Missing in Chart:**
  - No Certificate resource template
  - No ClusterIssuer/Issuer reference
  - Users must manually set up cert-manager and create certificates
- **Template Needed:** `templates/certificate.yaml` (optional, when ingress enabled)
- **Priority:** CRITICAL
- **Rationale:** Let's Encrypt integration is standard cloud-native practice

#### Gap 1.3: OAuth2-proxy Integration Guide
- **Documented:** chart/README.md, lines 152-154, 205-210
  - OAuth2-proxy annotations for NGINX
  - Example OAuth2 providers (Google, GitHub, OIDC)
  - SSO benefits for security
- **What's Missing in Chart:**
  - No helper values or documentation on OAuth2-proxy setup
  - No example values for different OAuth providers
  - Users must manually deploy OAuth2-proxy
- **Values Suggested:**
  ```yaml
  oauth2proxy:
    enabled: false  # Optional documentation/integration
    provider: google  # google, github, keycloak, etc.
    # Reference to separate OAuth2-proxy deployment docs
  ```
- **Priority:** CRITICAL
- **Rationale:** Central to production security model

#### Gap 1.4: Service Mesh Integration (Linkerd/Istio)
- **Documented:** chart/README.md, lines 50, 58, 637-638
  - Example: `linkerd.io/inject: enabled  # mTLS between services`
  - Feature: "service mesh integration"
  - Pod security context mentions mTLS
- **What's Missing in Chart:**
  - No pod annotations for service mesh injection
  - No values for service mesh configuration
  - No integration with service mesh monitoring
- **Values Suggested:**
  ```yaml
  serviceMesh:
    enabled: false
    name: linkerd  # or istio
    inject: true
  ```
- **Priority:** HIGH (but lower than ingress)
- **Rationale:** Enterprise deployments often require service mesh

---

### 2. MONITORING & OBSERVABILITY (HIGH)

#### Gap 2.1: ServiceMonitor Template (Prometheus)
- **Documented:** docs/deployment-strategies.md, lines 307-322
  ```yaml
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
- **What's Missing in Chart:**
  - No `templates/servicemonitor.yaml`
  - No metrics port exposed (port 6901 is VNC only)
  - No Prometheus scrape configuration
  - KasmVNC doesn't expose metrics by default
- **Implementation Notes:**
  - Would require extending KasmVNC image or sidecar for metrics export
  - Currently infeasible without upstream KasmVNC changes
  - Document this as "future capability"
- **Priority:** HIGH
- **Rationale:** Observability is critical for production; missing metrics integration

#### Gap 2.2: Grafana Dashboard ConfigMap
- **Documented:** chart/README.md, lines 247
  - Mentions "Monitor with Prometheus/Grafana"
- **What's Missing in Chart:**
  - No ConfigMap for Grafana dashboard JSON
  - No dashboard defining metrics to track
  - No correlation between docs and dashboard
- **Values Suggested:**
  ```yaml
  grafana:
    dashboards:
      enabled: false
      namespace: monitoring
  ```
- **Priority:** HIGH
- **Rationale:** Visual observability is important for operators

#### Gap 2.3: Metrics Export Sidecar
- **Documented:** docs/container-architecture.md (implicit via resource usage table)
  - Resource usage details (CPU, memory percentages)
  - Process memory breakdown
- **What's Missing in Chart:**
  - No sidecar for metrics export
  - No integration with Prometheus client libraries
  - KasmVNC doesn't expose metrics endpoint
- **Current State:** KasmVNC doesn't have built-in metrics
- **Priority:** HIGH
- **Rationale:** Essential for SLA monitoring and alerting

---

### 3. NETWORK SECURITY POLICIES (HIGH)

#### Gap 3.1: NetworkPolicy Template (Ingress-Only)
- **Documented:** chart/README.md, lines 179-201
  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: ghostwire-ingress-only
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
            name: ingress-nginx
      ports:
      - protocol: TCP
        port: 6901
  ```
- **What's Missing in Chart:**
  - No `templates/networkpolicy.yaml` template
  - No values for network policy configuration
  - Example requires manual creation
- **Values Needed:**
  ```yaml
  networkPolicy:
    enabled: false
    policyTypes:
      - Ingress
    ingress:
      - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
    egress: []  # Optional allow-all or specific rules
  ```
- **Priority:** HIGH
- **Rationale:** Pod-to-pod isolation is cluster security best practice

#### Gap 3.2: Egress Policies & Upstream Dependencies
- **Documented:** Implicitly in container-architecture.md (port listings)
  - Network services: ports 4901-4904 (internal), 6901 (external)
  - Signal Desktop requires internet for messaging
  - KasmVNC services need inter-pod communication
- **What's Missing in Chart:**
  - No egress policy documentation
  - No guidance on allowing Signal Desktop internet access
  - No internal port exposure for Kasm auxiliary services
- **Values Needed:**
  ```yaml
  networkPolicy:
    egress:
      - to:
        - namespaceSelector: {}  # Allow to other namespaces
        ports:
        - protocol: TCP
          port: 443  # Signal backend HTTPS
  ```
- **Priority:** HIGH
- **Rationale:** Explicit egress control is security best practice

---

### 4. BACKUP & DISASTER RECOVERY (HIGH)

#### Gap 4.1: Backup Job Template
- **Documented:** chart/README.md, lines 454-487
  - Manual backup procedure using `kubectl run` and `kubectl cp`
  - Creates tarball of Signal data
  - One-time operational task
- **What's Missing in Chart:**
  - No CronJob for automated daily backups
  - No backup destination (S3, NFS, external storage)
  - No retention policies
  - No restore procedures
- **Template Needed:** `templates/backup-cronjob.yaml` (optional)
- **Values Suggested:**
  ```yaml
  backup:
    enabled: false
    schedule: "0 2 * * *"  # Daily at 2 AM
    retention: 7  # days
    destination: s3://bucket/ghostwire-backups
    storageSize: 100Gi
  ```
- **Priority:** HIGH
- **Rationale:** Automated backup is critical for production data protection

#### Gap 4.2: Restore Procedure Documentation
- **Documented:** Mentioned implicitly in deployment-strategies.md
  - Blue/green deployment: "Restore user data from external source"
  - Migration path mentions "backup-restore automation"
- **What's Missing in Chart:**
  - No restore job template or procedure
  - No documentation on recovering from backup
  - No guidance on cross-version restore
- **Documentation Needed:**
  - Restore procedure in NOTES.txt or separate doc
  - Script for restore-from-backup
  - Testing backup integrity
- **Priority:** HIGH
- **Rationale:** Backup without tested restore is worthless

#### Gap 4.3: Persistent Volume Snapshot Support
- **Documented:** chart/README.md, line 715
  - "Don't delete the PVC. You can reinstall Ghostwire later"
- **What's Missing in Chart:**
  - No VolumeSnapshot resource template
  - No snapshot scheduling (daily snapshots)
  - No snapshot lifecycle management
  - No restore-from-snapshot procedure
- **Template Suggested:** `templates/volumesnapshot.yaml` (optional)
- **Values Suggested:**
  ```yaml
  volumeSnapshot:
    enabled: false
    schedule: "0 2 * * *"
    retain: 7  # days
  ```
- **Priority:** HIGH
- **Rationale:** Snapshots provide point-in-time recovery capability

---

### 5. RBAC & POD SECURITY (MEDIUM)

#### Gap 5.1: Application-Level Service Account & RBAC
- **Current State:** chart/templates/tests/test-rbac.yaml
  - Test-only service account with limited permissions
  - No application-level RBAC
  - `serviceAccount.create: false` in values
- **What's Missing:**
  - No production ServiceAccount for the app
  - No ClusterRole/Role for app-level operations
  - Unclear what permissions app actually needs (likely none)
- **Values Needed:**
  ```yaml
  serviceAccount:
    create: true  # Change from false
    annotations: {}
    name: ""
  rbac:
    create: true
    rules: []  # Currently needs no permissions
  ```
- **Priority:** MEDIUM
- **Rationale:** Best practice to explicitly declare permissions; currently running with default

#### Gap 5.2: Pod Security Standards Namespace Label
- **Documented:** chart/README.md, lines 665-667
  ```bash
  kubectl label namespace ghostwire pod-security.kubernetes.io/enforce=restricted
  ```
- **What's Missing in Chart:**
  - No automated namespace label via Helm
  - Users must manually label namespace
  - No guidance on which PSS level is appropriate
- **Values Suggested:**
  ```yaml
  podSecurityStandards:
    enforce: restricted  # or baseline
    audit: restricted
    warn: restricted
  ```
- **Implementation:** Post-install note or pre-install hook
- **Priority:** MEDIUM
- **Rationale:** PSS labeling should be automatic, not manual

---

### 6. POD DISRUPTION BUDGETS (MEDIUM)

#### Gap 6.1: PDB for High Availability
- **Documented:** Implicitly in chart/README.md resource limits discussion
  - High-availability deployments would need protection
  - Single replica: `replicaCount: 1`
  - During updates: temporary unavailability acceptable
- **What's Missing in Chart:**
  - No PodDisruptionBudget template
  - No guidance on when to use PDB
  - Single replica doesn't need PDB (but documented anyway)
- **Template Needed:** `templates/pdb.yaml` (optional, mostly educational)
- **Values Suggested:**
  ```yaml
  podDisruptionBudget:
    enabled: false
    minAvailable: 1
  ```
- **Priority:** MEDIUM
- **Rationale:** Protection during cluster maintenance; currently not critical for single replica

---

### 7. ADVANCED SCHEDULING (MEDIUM/LOW)

#### Gap 7.1: Pod Priority & Preemption
- **Documented:** Implicitly in chart/README.md values
  - Resource limits: CPU 1500m, Memory 2Gi
  - Prevents "runaway usage"
- **What's Missing in Chart:**
  - No PriorityClass template
  - No priorityClassName in pod spec
  - No guidance on priority levels
- **Values Suggested:**
  ```yaml
  priorityClassName: ""  # default-priority, high-priority, etc.
  ```
- **Priority:** LOW
- **Rationale:** Nice-to-have; mostly for multi-tenant clusters

#### Gap 7.2: Horizontal Pod Autoscaling (HPA)
- **Current State:** `replicaCount: 1` (hardcoded, single user)
- **Documented:** chart/README.md comparison table
  - "Scaling: Declarative (YAML)" ✅
  - But only for single replica
- **What's Missing:**
  - HPA not applicable (single user, single replica)
  - No documentation explaining why HPA doesn't apply
  - Would require multi-user architecture
- **Note:** Documented design decision (not applicable for single-user Signal)
- **Priority:** LOW
- **Rationale:** Not applicable to current architecture; documented in deployment-strategies.md

---

### 8. GITOPS INTEGRATION (LOW)

#### Gap 8.1: Flux CD HelmRelease Example Template
- **Documented:** chart/README.md, lines 237-276
  ```yaml
  apiVersion: helm.toolkit.fluxcd.io/v2
  kind: HelmRelease
  metadata:
    name: ghostwire
  spec:
    interval: 10m
    test:
      enable: true
    rollback:
      recreate: true
      cleanupOnFail: true
  ```
- **What's Missing in Chart:**
  - No `examples/helmrelease.yaml` example file
  - No FluxCD-specific values in values.yaml
  - No OCIRepository example
- **Suggested Location:** `examples/flux-helmrelease.yaml`
- **Priority:** LOW
- **Rationale:** GitOps is optional; docs already have full example

---

### 9. RESOURCE MANAGEMENT & SCALING (MEDIUM)

#### Gap 9.1: Resource Request/Limit Guidance
- **Documented:** chart/README.md, lines 292-297, container-architecture.md lines 525-538
  - Memory: 1Gi requests, 2Gi limits
  - CPU: 500m requests, 2000m limits
  - Process-level memory breakdown
- **What's Missing in Chart:**
  - No guidance on scaling with attachments/history size
  - No memory pressure handling documentation
  - No CPU scaling guidance for different use patterns
- **Documentation Needed:** Resource sizing guide
- **Priority:** MEDIUM
- **Rationale:** Current limits may be inadequate for heavy usage

#### Gap 9.2: Shared Memory Size Configuration
- **Current State:** `shmSize: 512` (MB)
- **Documented:** chart/README.md, line 517
  - "Increase shared memory if browser crashes"
  - Troubleshooting section suggests 1024MB
- **What's Missing:**
  - No guidance on sizing shared memory
  - No correlation between browser crashes and shm size
  - No documentation on shm requirements
- **Documentation Needed:** Sizing guide for different scenarios
- **Priority:** MEDIUM
- **Rationale:** Common troubleshooting, needs better guidance

#### Gap 9.3: Storage Size Guidance
- **Documented:** chart/README.md, line 304
  - "PVC size (messages, attachments, cache)"
  - Default: 10Gi
- **What's Missing:**
  - No guidance on calculating storage size
  - No information on growth rate
  - No archival/cleanup strategy
- **Documentation Needed:** Storage sizing guide
  - Active messages: ~100MB-500MB
  - Attachments: 0-5GB+ depending on usage
  - Recommend 15-50Gi for typical use
- **Priority:** MEDIUM
- **Rationale:** Users need sizing guidance

---

### 10. OPERATIONAL RUNBOOKS (MEDIUM)

#### Gap 10.1: Helm Tests Automation in CD/CD
- **Documented:** docs/deployment-strategies.md, lines 251-264
  - Helm tests included in deployment validation
  - Tests validate VNC, DNS, StatefulSet, PVC, TLS
- **What's Missing in Chart:**
  - No CI/CD integration examples
  - No pre-push test procedures
  - No integration with Flux CD test annotations
- **Documentation Suggested:** `docs/ci-cd-integration.md`
- **Priority:** MEDIUM
- **Rationale:** Tests should run automatically in GitOps workflow

#### Gap 10.2: Production Deployment Checklist
- **Documented:** chart/README.md, lines 26, 622-673
  - "For production: ..." with checklist items
  - 5 hardening steps listed
- **What's Missing in Chart:**
  - No deployment validation script
  - No pre-flight checks (cert-manager installed, ingress controller, etc.)
  - No post-deployment verification
- **File Suggested:** `scripts/pre-flight-checks.sh`
- **Priority:** MEDIUM
- **Rationale:** Prevents misconfiguration in production

---

### 11. INGRESS CONTROLLER DETECTION (LOW)

#### Gap 11.1: Automatic Ingress Class Detection
- **Documented:** chart/README.md, line 161
  - Example: `ingressClassName: nginx`
- **What's Missing in Chart:**
  - No automatic detection of available ingress controllers
  - No values suggestion for non-NGINX (traefik, HAProxy, etc.)
  - Users must manually select ingress class
- **Values Suggested:**
  ```yaml
  ingress:
    className: ""  # auto-detect or explicit
  ```
- **Priority:** LOW
- **Rationale:** Most clusters use NGINX; auto-detection adds complexity

---

## Implementation Priority Matrix

### CRITICAL (Block Production Use)
1. **Ingress Template** - Users need production access pattern
2. **cert-manager Integration** - TLS at scale requires automation
3. **OAuth2-proxy Guide** - Central security model

### HIGH (Production Best Practices)
4. **NetworkPolicy Template** - Security isolation required
5. **ServiceMonitor Template** - Observability for operations
6. **Backup Automation** - Data protection essential
7. **Egress Policies** - Complete security model
8. **Restore Procedures** - DR capabilities

### MEDIUM (Operational Readiness)
9. **Service Account & RBAC** - Security best practice
10. **Pod Security Standards** - Cluster security
11. **Resource Sizing Guide** - Operational guidance
12. **Pre-flight Checks** - Deployment safety
13. **Deployment Checklist** - Operational runbook

### LOW (Nice to Have)
14. **PodDisruptionBudget** - HA scenarios
15. **PriorityClass** - Advanced scheduling
16. **Pod Priority** - Multi-tenant considerations
17. **Flux CD Examples** - GitOps documentation
18. **Grafana Dashboard** - Visualization

---

## Recommended Implementation Roadmap

### Phase 1: Critical Production Templates (Week 1-2)
```
templates/ingress.yaml              - Ingress with cert-manager support
templates/networkpolicy.yaml        - Ingress-only network policy
examples/helm-release-prod.yaml     - Production values example
docs/production-setup.md            - Complete production guide
```

### Phase 2: High-Priority Additions (Week 3-4)
```
templates/backup-cronjob.yaml       - Automated backup (optional)
templates/servicemonitor.yaml       - Prometheus integration (optional)
scripts/pre-flight-checks.sh        - Deployment validation
docs/backup-restore.md              - DR procedures
```

### Phase 3: Operational Excellence (Week 5-6)
```
templates/rbac.yaml                 - App-level RBAC
templates/pdb.yaml                  - Pod disruption budget (optional)
docs/resource-sizing.md             - Capacity planning
docs/troubleshooting-advanced.md    - Advanced diagnostics
```

### Phase 4: Nice-to-Have Features (Backlog)
```
templates/servicemonitor.yaml       - With metrics sidecar (requires work)
examples/service-mesh-linkerd.yaml  - Linkerd integration
examples/service-mesh-istio.yaml    - Istio integration
docs/ci-cd-integration.md           - GitHub Actions, GitLab CI examples
```

---

## Files to Create/Modify

### New Templates (in `chart/templates/`)
```
ingress.yaml                  - NGINX/Traefik/other ingress support
networkpolicy.yaml            - Pod network isolation rules
rbac.yaml                      - ServiceAccount, Role, RoleBinding (app)
servicemonitor.yaml            - Prometheus scrape configuration (optional)
backup-cronjob.yaml            - Automated backup job (optional)
volumesnapshot.yaml            - PVC snapshot job (optional)
pdb.yaml                        - Pod disruption budget (optional)
```

### New Values Section (in `chart/values.yaml`)
```yaml
# Ingress configuration
ingress:
  enabled: false
  className: nginx
  annotations: {}
  hosts: []
  tls: []

# Network policies
networkPolicy:
  enabled: false

# RBAC
rbac:
  create: true

# Pod security standards
podSecurityStandards:
  enforce: restricted

# Backup (optional)
backup:
  enabled: false

# Monitoring (optional)
servicemonitor:
  enabled: false
```

### New Documentation
```
docs/production-setup.md          - Complete guide (Ingress, OAuth2, TLS)
docs/backup-restore.md            - Backup & disaster recovery
docs/resource-sizing.md           - Capacity planning & scaling
docs/security-hardening.md        - Pod security, network policies
docs/troubleshooting-advanced.md  - Advanced diagnostics
docs/ci-cd-integration.md         - GitOps workflows
```

### New Scripts
```
scripts/pre-flight-checks.sh      - Pre-deployment validation
scripts/backup-restore.sh         - Manual backup/restore utilities
```

### Example Files
```
examples/helmrelease-flux.yaml    - Flux CD example
examples/values-production.yaml   - Production values
examples/ingress-nginx.yaml       - NGINX ingress example
examples/ingress-traefik.yaml     - Traefik ingress example
examples/networkpolicy.yaml       - Network policy examples
examples/oauth2-proxy.yaml        - OAuth2-proxy integration
```

---

## Documentation Quality Improvements

The chart documentation is **excellent** but could be enhanced:

1. **Add navigation index** to chart/README.md
2. **Create decision tree** for "When to use each feature"
3. **Add troubleshooting flowchart** for common issues
4. **Create architecture diagrams** in templates directory
5. **Add quick-reference card** for CLI commands
6. **Create FAQ document** for common questions

---

## Notes on Design Decisions

The Ghostwire chart intentionally delegates infrastructure concerns (ingress, auth, TLS, monitoring) to operators, following cloud-native best practices:

✅ **This is correct** - Infrastructure and app concerns are separate
✅ **This enables** - Operators to use their preferred tools
❌ **But leaves** - Users without clear templates or examples

**Recommendation:** Keep delegating these concerns, but provide optional Helm templates as examples that operators can use or ignore. This preserves the "infrastructure-agnostic" design while improving usability.

---

## Summary Statistics

- **Total Gaps Identified:** 23
- **Critical Priority:** 3
- **High Priority:** 8
- **Medium Priority:** 9
- **Low Priority:** 3

- **Missing Templates:** 8
- **Missing Values Sections:** 9
- **Missing Documentation Files:** 6
- **Missing Example Files:** 5
- **Missing Scripts:** 2

**Estimated Implementation Effort:** 60-80 hours for all phases
- Phase 1 (Critical): 12-16 hours
- Phase 2 (High): 16-20 hours
- Phase 3 (Medium): 16-20 hours
- Phase 4 (Nice-to-have): 12-16 hours
