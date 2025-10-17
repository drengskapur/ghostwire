# Ghostwire Chart: Gaps Quick Reference

**Last Updated:** October 17, 2025  
**Total Gaps:** 23 | **Critical:** 3 | **High:** 8 | **Medium:** 9 | **Low:** 3

---

## CRITICAL - Production Blockers (Must Implement)

| Gap | File(s) | Template | Values | Doc |
|-----|---------|----------|--------|-----|
| Ingress Template | `templates/ingress.yaml` | ❌ | ❌ | README.md:140-177 |
| cert-manager Integration | `templates/ingress.yaml` | ❌ | ❌ | README.md:149-150 |
| OAuth2-proxy Guide | - | - | ❌ | README.md:152-154 |

---

## HIGH PRIORITY - Production Best Practices (Strong Recommendations)

| Gap | File(s) | Template | Values | Doc |
|-----|---------|----------|--------|-----|
| NetworkPolicy Template | `templates/networkpolicy.yaml` | ❌ | ❌ | README.md:179-201 |
| Egress Policies | `templates/networkpolicy.yaml` | ❌ | ❌ | README.md:634-635 |
| ServiceMonitor (Prometheus) | `templates/servicemonitor.yaml` | ❌ | ❌ | deployment-strategies.md:307-322 |
| Grafana Dashboard | `templates/configmap-dashboard.yaml` | ❌ | ❌ | README.md:247 |
| Backup Automation | `templates/backup-cronjob.yaml` | ❌ | ❌ | README.md:454-487 |
| Restore Procedures | - | - | - | ❌ NEW DOC NEEDED |
| Service Mesh (Linkerd/Istio) | - | - | ❌ | README.md:50,58,637-638 |

---

## MEDIUM PRIORITY - Operational Readiness

| Gap | File(s) | Template | Values | Doc |
|-----|---------|----------|--------|-----|
| Service Account + RBAC | `templates/rbac.yaml` | ❌ | ❌ | - |
| Pod Security Standards | - | - | ❌ | README.md:665-667 |
| Pod Disruption Budget | `templates/pdb.yaml` | ❌ | ❌ | - |
| Resource Sizing Guide | - | - | - | ❌ NEW DOC NEEDED |
| SHM Sizing Guide | - | - | - | ❌ NEW DOC NEEDED |
| Storage Sizing Guide | - | - | - | ❌ NEW DOC NEEDED |
| Helm Tests in CI/CD | - | - | - | ❌ NEW DOC NEEDED |
| Pre-flight Checks | `scripts/pre-flight-checks.sh` | - | - | ❌ NEW DOC NEEDED |
| VolumeSnapshot Support | `templates/volumesnapshot.yaml` | ❌ | ❌ | - |

---

## LOW PRIORITY - Nice-to-Have

| Gap | File(s) | Template | Values | Doc |
|-----|---------|----------|--------|-----|
| Pod Priority | - | - | ❌ | - |
| Flux CD Examples | `examples/helmrelease-flux.yaml` | - | - | ❌ NEW DOC NEEDED |
| Ingress Class Auto-detection | - | - | ❌ | - |
| HPA Documentation | - | - | - | deployment-strategies.md (already there) |

---

## Summary by Type

### Templates to Create (8 total)
1. `chart/templates/ingress.yaml` - **CRITICAL**
2. `chart/templates/networkpolicy.yaml` - **HIGH**
3. `chart/templates/servicemonitor.yaml` - **HIGH** (blocked by KasmVNC metrics)
4. `chart/templates/rbac.yaml` - **MEDIUM**
5. `chart/templates/pdb.yaml` - **MEDIUM**
6. `chart/templates/backup-cronjob.yaml` - **HIGH** (optional)
7. `chart/templates/volumesnapshot.yaml` - **HIGH** (optional)
8. `chart/templates/configmap-dashboard.yaml` - **HIGH** (optional)

### Values Sections to Add (9 total)
1. `ingress: { enabled, className, hosts, tls, annotations }` - **CRITICAL**
2. `networkPolicy: { enabled, policyTypes, ingress, egress }` - **HIGH**
3. `rbac: { create, rules }` - **MEDIUM**
4. `serviceMesh: { enabled, name, inject }` - **HIGH**
5. `oauth2proxy: { enabled, provider }` - **CRITICAL**
6. `podSecurityStandards: { enforce, audit, warn }` - **MEDIUM**
7. `servicemonitor: { enabled, interval, namespace }` - **HIGH**
8. `backup: { enabled, schedule, retention, destination }` - **HIGH**
9. `volumeSnapshot: { enabled, schedule, retain }` - **HIGH**

### Documentation to Create (6 new docs + updates)
1. `docs/production-setup.md` - Complete ingress + OAuth2 setup - **CRITICAL**
2. `docs/backup-restore.md` - Backup/restore procedures - **HIGH**
3. `docs/resource-sizing.md` - CPU/memory/storage guidance - **MEDIUM**
4. `docs/security-hardening.md` - All security configs - **MEDIUM**
5. `docs/ci-cd-integration.md` - Helm tests + Flux CD workflows - **MEDIUM**
6. `docs/troubleshooting-advanced.md` - Advanced diagnostics - **MEDIUM**

### Scripts to Create (2 total)
1. `scripts/pre-flight-checks.sh` - Validate cluster ready for deployment - **MEDIUM**
2. `scripts/backup-restore.sh` - Manual backup/restore utilities - **HIGH**

### Examples to Create (5 total)
1. `examples/values-production.yaml` - Production values reference
2. `examples/ingress-nginx.yaml` - NGINX ingress example
3. `examples/ingress-traefik.yaml` - Traefik ingress example
4. `examples/helmrelease-flux.yaml` - Flux CD integration
5. `examples/networkpolicy-complete.yaml` - Full network policy

---

## Implementation Effort Estimate

| Phase | Duration | Focus | Complexity |
|-------|----------|-------|-----------|
| Phase 1: Critical | 12-16 hrs | Ingress, cert-manager, OAuth2 guide | ⭐⭐⭐ |
| Phase 2: High Priority | 16-20 hrs | NetworkPolicy, backup, monitoring | ⭐⭐ |
| Phase 3: Medium Priority | 16-20 hrs | RBAC, PDB, documentation | ⭐ |
| Phase 4: Nice-to-Have | 12-16 hrs | Examples, advanced features | ⭐ |
| **TOTAL** | **60-80 hrs** | **Full cloud-native readiness** | - |

---

## Quick Start: What to Implement First

### Week 1-2 (Critical Path)
```
✅ Add Ingress template with cert-manager support
✅ Add NetworkPolicy template
✅ Create production-setup.md with complete examples
✅ Add ingress values to values.yaml
```

### Week 3-4 (High Priority)
```
✅ Add backup-cronjob.yaml template
✅ Add NetworkPolicy egress rules
✅ Create backup-restore.md documentation
✅ Add scripts/pre-flight-checks.sh
```

### Week 5+ (Medium/Low Priority)
```
✅ Add RBAC templates
✅ Add resource sizing documentation
✅ Add example files
✅ Enhance troubleshooting docs
```

---

## Notes

- **Design Intent:** Chart deliberately delegates infrastructure concerns (ingress, TLS, auth) to operators
- **Recommendation:** Add optional templates/values to guide operators without forcing choices
- **Blocker:** ServiceMonitor requires KasmVNC to export metrics (upstream work needed)
- **Status:** Documentation is excellent; implementation gaps are deliberate design choices

See `IMPLEMENTATION_GAPS.md` for full analysis with code examples and rationale.
