# Ghostwire Chart: Documentation References for Implementation Gaps

This document maps each implementation gap to its source in the documentation.

---

## Documentation Sources

### chart/README.md (Primary Helm Chart Documentation)
- Lines 1-63: Overview and quick-start
- Lines 80-111: Production setup with Ingress example
- Lines 140-177: Ingress template example with OAuth2, cert-manager, WebSocket
- Lines 179-201: NetworkPolicy example
- Lines 207-217: Security best practices
- Lines 237-276: Flux CD HelmRelease example
- Lines 280-324: Configuration tables
- Lines 292-297: Resource configuration
- Lines 304: Persistence configuration
- Lines 403-487: Common tasks including manual backup procedure
- Lines 454-487: Backup procedure with tarball creation
- Lines 517: Troubleshooting - increase shared memory
- Lines 541-553: WebSocket/Ingress troubleshooting
- Lines 622-673: Security best practices section
- Lines 629: cert-manager.io/cluster-issuer annotation
- Lines 632: OAuth2-proxy integration
- Lines 637-638: Service mesh integration (Linkerd)
- Lines 659-673: Network policies, Pod Security Standards labels
- Lines 688-698: Feature comparison table

### docs/container-architecture.md (Container Runtime Details)
- Lines 42-84: Network architecture showing port 6901 + auxiliary services
- Lines 156-181: Audio data flow diagram
- Lines 318-331: Audio services breakdown
- Lines 352-400: KasmVNC auxiliary services details
- Lines 525-538: Process resource usage table (CPU, memory percentages)
- Lines 676-702: Network services and listening ports
- Lines 708-764: Authentication system details
- Lines 775-830: TLS/SSL configuration
- Lines 1097-1114: DLP (Data Loss Prevention) controls

### docs/deployment-strategies.md (Advanced Deployment Patterns)
- Lines 239-286: Recommended approach section
- Lines 251-264: Enhanced Helm tests validation
- Lines 266-286: Flux CD automated rollback example
- Lines 288-305: Health checks (liveness/readiness probes)
- Lines 307-322: Monitoring with Prometheus/Grafana and ServiceMonitor example
- Lines 324-346: Migration paths (blue/green, ephemeral with backup/restore)

---

## Gap-to-Documentation Mapping

### CRITICAL GAPS

#### 1. Ingress Template
**Sources:**
- chart/README.md:140-177 - Complete NGINX Ingress with OAuth2-proxy, cert-manager, WebSocket timeouts
- chart/README.md:131-177 - Step 2 production setup
- chart/README.md:237-276 - Flux CD example showing Ingress integration

**Key Requirements from Docs:**
- NGINX ingress class
- cert-manager annotations for Let's Encrypt
- OAuth2-proxy auth annotations
- WebSocket support with 3600s timeouts
- TLS with automatic Let's Encrypt certificates

#### 2. cert-manager Integration
**Sources:**
- chart/README.md:149-150 - Annotation example
- chart/README.md:629 - cert-manager.io/cluster-issuer example
- chart/README.md:214 - "Automatic certificate rotation (cert-manager)"

**Key Requirements from Docs:**
- Integration with Let's Encrypt for automatic TLS
- ClusterIssuer or Issuer reference
- Auto-renewal of certificates
- Annotation-based triggering

#### 3. OAuth2-proxy Integration Guide
**Sources:**
- chart/README.md:152-154 - OAuth2-proxy annotations
- chart/README.md:205-210 - Benefits listed
- chart/README.md:45-52 - Cloud-native approach to authentication
- chart/README.md:631-632 - Auth annotation format

**Key Requirements from Docs:**
- Single sign-on via OAuth2/OIDC
- Support for Google, GitHub, Keycloak providers
- Centralized auth logs
- No VNC password (auth at ingress level)

---

### HIGH PRIORITY GAPS

#### 4. NetworkPolicy Template (Ingress-Only)
**Sources:**
- chart/README.md:179-201 - Complete NetworkPolicy example
- chart/README.md:659-663 - Instructions to enable network policies
- chart/README.md:197-198 - Reference to ingress-nginx namespace label

**Key Requirements from Docs:**
- Allow ingress only from ingress-nginx namespace
- Restrict pod-to-pod traffic
- Optional egress rules
- Port 6901 exposure

#### 5. Egress Policies & Upstream Dependencies
**Sources:**
- chart/README.md:634-635 - Network policies section
- container-architecture.md:42-84 - Network services diagram
- container-architecture.md:676-702 - Listening ports table
- deployment-strategies.md:247 - Signal requires internet connectivity

**Key Requirements from Docs:**
- Allow Signal Desktop to reach signal.org backends (HTTPS 443)
- Allow inter-pod communication within namespace
- Restrict unnecessary external access
- No egress by default, explicit allow rules

#### 6. ServiceMonitor Template (Prometheus)
**Sources:**
- docs/deployment-strategies.md:307-322 - ServiceMonitor YAML example
- deployment-strategies.md:247 - "Monitor with Prometheus/Grafana"
- deployment-strategies.md:249-250 - Monitoring as part of validation

**Key Requirements from Docs:**
- monitoring.coreos.com/v1 ServiceMonitor API
- Scrape configuration with 30s interval
- Label selector matching ghostwire pods
- Metrics endpoint on port (currently missing)

**Note:** KasmVNC doesn't export metrics by default; requires upstream changes

#### 7. Grafana Dashboard ConfigMap
**Sources:**
- chart/README.md:247 - "Monitor with Prometheus/Grafana"
- deployment-strategies.md:247-250 - Monitoring section

**Key Requirements from Docs:**
- Grafana dashboard JSON ConfigMap
- Resource usage visualization
- Uptime/availability metrics
- Pod health status

#### 8. Backup Automation (CronJob)
**Sources:**
- chart/README.md:454-487 - Manual backup procedure documented
- chart/README.md:339 - "Pod restarts" imply data persistence need
- deployment-strategies.md:324-346 - "backup-restore automation" mentioned
- deployment-strategies.md:1-2 - "Make Signal data portable/backup-restore"

**Key Requirements from Docs:**
- Automated daily backup to S3 or external storage
- Retention policy (7+ days)
- Backup of /home/kasm-user/.config/Signal directory
- Tarball compression with timestamp
- Manual procedure shown: `tar czf /backup/signal-backup.tar.gz -C /data .`

#### 9. Restore Procedures Documentation
**Sources:**
- deployment-strategies.md:343 - "Restore user data from external source"
- deployment-strategies.md:345 - "Allow blue/green with data migration"
- chart/README.md:715 - "You can reinstall Ghostwire later" implies restore capability

**Key Requirements from Docs:**
- Restore-from-backup procedures
- Cross-version migration
- Testing backup integrity
- Rollback procedures

#### 10. Service Mesh Integration (Linkerd/Istio)
**Sources:**
- chart/README.md:50 - "service mesh integration"
- chart/README.md:58 - Feature list mentions "service mesh integration"
- chart/README.md:637-638 - Example annotation `linkerd.io/inject: enabled`
- chart/README.md:638 - "mTLS between services"

**Key Requirements from Docs:**
- Pod annotations for service mesh injection
- mTLS configuration
- Service mesh monitoring integration
- Both Linkerd and Istio support

---

### MEDIUM PRIORITY GAPS

#### 11. Service Account + RBAC
**Sources:**
- chart/templates/tests/test-rbac.yaml - Test-only RBAC (ServiceAccount, Role, RoleBinding)
- values.yaml:268-271 - `serviceAccount.create: false` currently

**Key Requirements from Docs:**
- Application-level ServiceAccount (currently runs as default)
- Explicit RBAC rules (likely empty, but best practice to declare)
- Test access pattern already defined in test-rbac.yaml

#### 12. Pod Security Standards Namespace Label
**Sources:**
- chart/README.md:667 - Command: `kubectl label namespace ghostwire pod-security.kubernetes.io/enforce=restricted`
- chart/README.md:665-668 - "Use Pod Security Standards"

**Key Requirements from Docs:**
- Automated namespace labeling on install
- Three label types: enforce, audit, warn
- "restricted" as target PSS level

#### 13. Pod Disruption Budget
**Sources:**
- Implied in chart/README.md resource limits discussion
- Mentioned in Kubernetes best practices context

**Key Requirements from Docs:**
- PDB template (even if not strictly needed for single replica)
- Protection during cluster maintenance
- minAvailable: 1 for production

#### 14. Resource Sizing Guide
**Sources:**
- chart/README.md:292-297 - Resource configuration tables
- container-architecture.md:525-538 - Process resource usage table
- chart/README.md:517 - "Increase shared memory if browser crashes"
- chart/README.md:304 - Storage size guidance needed

**Key Requirements from Docs:**
- Memory: 1Gi requests, 2-4Gi limits (data-dependent)
- CPU: 500m requests, 1500-2000m limits
- SHM sizing guidance (512-1024MB)
- Storage calculation based on attachments

#### 15. Shared Memory Size Configuration Guide
**Sources:**
- chart/README.md:517 - "Increase shared memory if browser crashes"
- chart/README.md:519 - helm upgrade example with shmSize=1024
- values.yaml:222-224 - `shmSize: 512`

**Key Requirements from Docs:**
- Current default: 512MB
- Troubleshooting: increase to 1024MB for browser stability
- No documented correlation between shm size and functionality

#### 16. Storage Size Guidance
**Sources:**
- chart/README.md:304 - "PVC size (messages, attachments, cache)"
- values.yaml:94 - Default 10Gi
- container-architecture.md:550-593 - Home directory structure

**Key Requirements from Docs:**
- Default 10Gi may be too small for heavy usage
- Need calculation based on:
  - Active message cache: ~100-500MB
  - Attachments: 0-5GB+ depending on usage
  - Recommended: 15-50Gi

#### 17. Helm Tests in CI/CD
**Sources:**
- deployment-strategies.md:251-264 - "Enhanced Helm Tests"
- deployment-strategies.md:254-263 - Tests validate VNC, DNS, StatefulSet, PVC, TLS
- deployment-strategies.md:275 - `test: enable: true` in Flux HelmRelease

**Key Requirements from Docs:**
- Integration with CI/CD pipelines
- Pre-push validation
- Flux CD test automation
- No push without passing tests

#### 18. Pre-flight Checks Script
**Sources:**
- chart/README.md:659-673 - Hardening steps imply pre-checks needed
- Implied in production setup section

**Key Requirements from Docs:**
- Check cert-manager installed
- Check ingress controller available
- Check StorageClass available
- Validate cluster prerequisites
- Check resource availability

#### 19. VolumeSnapshot Support
**Sources:**
- chart/README.md:715 - "Don't delete the PVC. You can reinstall Ghostwire later"
- deployment-strategies.md:345 - Snapshots mentioned for blue/green

**Key Requirements from Docs:**
- Point-in-time recovery capability
- Scheduled daily snapshots
- Retention policy
- Restore from snapshot procedure

---

### LOW PRIORITY GAPS

#### 20. Pod Priority & Preemption
**Sources:**
- values.yaml:102-113 - Resource limits prevent "runaway usage"
- Implied in scheduling best practices

**Key Requirements from Docs:**
- PriorityClass support for multi-tenant clusters
- Preemption configuration
- Priority levels

#### 21. Flux CD Examples (Extended)
**Sources:**
- chart/README.md:237-276 - HelmRelease example
- chart/README.md:239-250 - OCIRepository example

**Key Requirements from Docs:**
- Full GitOps workflow example
- Test automation in HelmRelease
- Rollback configuration
- Automated remediation

#### 22. Ingress Class Auto-detection
**Sources:**
- chart/README.md:161 - `ingressClassName: nginx`
- Implied in multi-cluster scenarios

**Key Requirements from Docs:**
- Auto-detect available ingress controllers
- Fall back to default if not specified
- Support for NGINX, Traefik, HAProxy

#### 23. Production Values Example
**Sources:**
- chart/README.md:83-105 - values-production.yaml example in docs
- chart/README.md:108 - Install command with -f values-production.yaml

**Key Requirements from Docs:**
- Complete example values file for production
- auth: enabled=false
- tls: mode=disabled
- service: type=ClusterIP
- resources and persistence properly sized

---

## Documentation Quality Assessment

### Excellent Documentation
✅ Overall structure and organization
✅ Quick-start guide with examples
✅ Production setup with detailed steps
✅ Security best practices section
✅ Comprehensive troubleshooting
✅ Architecture diagrams (mermaid)
✅ Feature comparisons

### Areas for Enhancement
⚠️ Ingress examples shown but no template provided
⚠️ OAuth2-proxy mentioned but no setup helper
⚠️ NetworkPolicy example shown but not templated
⚠️ Backup procedures manual-only
⚠️ Resource sizing guidance incomplete
⚠️ No pre-flight checks documented
⚠️ ServiceMonitor example but metrics unavailable (upstream blocker)

### Documented Design Decisions
✅ Cloud-native approach: infrastructure-level security delegated to operators
✅ Single-user architecture: HPA not applicable
✅ StatefulSet: explained vs Deployment/Rollout trade-offs
✅ No ingress by default: intentional for flexibility

---

## Recommendations

1. **Convert Examples to Templates:** CRITICAL
   - Take Ingress example from README and create optional template
   - Same for NetworkPolicy

2. **Create Helper Documentation:** HIGH
   - Separate docs for OAuth2-proxy, cert-manager setup
   - Link from README to detailed guides

3. **Add Operational Guides:** MEDIUM
   - Pre-flight checks
   - Backup/restore procedures
   - Resource sizing calculator

4. **Enhance with Examples:** LOW
   - Multiple ingress controller examples (Traefik, HAProxy)
   - Service mesh integration examples
   - Different OAuth2 providers

---

## Document Reference Summary

| Document | Lines | Primary Focus | Gaps Addressed |
|----------|-------|---------------|-----------------|
| chart/README.md | 747 | Helm values, setup, examples | 1,2,3,4,5,7,10,12,14,15,16,21,22,23 |
| docs/deployment-strategies.md | 373 | Deployment patterns, monitoring | 6,8,9,11,18 |
| docs/container-architecture.md | 1169 | Runtime, network, resources | 5,14,16 |
| values.yaml | 307 | Configuration defaults | 11,12,15,16 |
| templates/tests/test-rbac.yaml | 45 | RBAC pattern | 11 |

**Total Documentation Lines:** 2,641
**Total Gaps Identified:** 23
**Average Documentation-to-Gap Ratio:** ~115 lines per gap

