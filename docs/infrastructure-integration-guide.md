# Infrastructure Integration Guide

## Ghostwire's Cloud-Native Architecture

Ghostwire follows cloud-native best practices by **delegating infrastructure concerns** to your existing Kubernetes infrastructure layer. This guide shows you how to integrate Ghostwire with common infrastructure components.

## Design Philosophy

The Ghostwire Helm chart intentionally **does not include**:

- Built-in ingress configuration
- Embedded TLS/certificate management
- Application-level authentication
- Network policies
- Monitoring/observability configuration

**Why?** Because you already have infrastructure for these!

Instead of duplicating or conflicting with your existing:

- Ingress controller (nginx, Traefik, Istio, etc.)
- Certificate manager (cert-manager, Let's Encrypt, etc.)
- Authentication provider (OAuth2-proxy, Keycloak, Authentik, etc.)
- Monitoring stack (Prometheus, Grafana, Datadog, etc.)
- Security policies (OPA, Kyverno, etc.)

Ghostwire provides **integration patterns** you can apply using your existing tools.

---

## Quick Reference

| Integration | Your Tool Options | See Guide |
|-------------|------------------|-----------|
| **Ingress** | nginx, Traefik, Istio, Contour | [integration-patterns.md](integration-patterns.md#ingress) |
| **TLS/Certificates** | cert-manager, Let's Encrypt, external | [integration-patterns.md](integration-patterns.md#tls) |
| **Authentication** | OAuth2-proxy, Keycloak, Authentik | [integration-patterns.md](integration-patterns.md#auth) |
| **Network Isolation** | NetworkPolicy, Calico, Cilium | [integration-patterns.md](integration-patterns.md#network) |
| **Monitoring** | Prometheus, Datadog, New Relic | [integration-patterns.md](integration-patterns.md#monitoring) |
| **Backup** | Velero, Kasten K10, custom scripts | [integration-patterns.md](integration-patterns.md#backup) |
| **Service Mesh** | Linkerd, Istio, Consul | [integration-patterns.md](integration-patterns.md#service-mesh) |
| **GitOps** | Flux CD, Argo CD | [integration-patterns.md](integration-patterns.md#gitops) |

---

## Integration Guides

### For Different Roles

**Platform Engineers:**

- See [integration-patterns.md](integration-patterns.md) for infrastructure layer integration patterns
- See [infrastructure-layer-options.md](infrastructure-layer-options.md) for detailed implementation options

**Application Teams:**

- See [integration-examples.md](integration-examples.md) for ready-to-use YAML examples
- See chart [README.md](../chart/README.md) for quickstart

**Security Teams:**

- See [infrastructure-layer-options.md](infrastructure-layer-options.md#security) for security hardening options
- See [integration-patterns.md](integration-patterns.md#network) for network isolation patterns

---

## What's Included vs What You Bring

### ✅ Included in Ghostwire Chart

**Application Layer:**

- Signal Desktop container runtime
- StatefulSet with persistent storage
- Service for internal routing
- Health probes (liveness/readiness)
- Resource limits and requests
- Security contexts (non-root, capabilities drop)
- VNC server configuration

**Cloud-Native Defaults:**

- No built-in auth (use your OAuth2 provider)
- No built-in TLS (use your cert-manager)
- ClusterIP service (expose via your ingress)
- Minimal RBAC (just what the app needs)

### 🔧 You Integrate (Your Infrastructure)

**Infrastructure Layer:**

- Ingress controller + routing rules
- TLS certificates (cert-manager, external CA, etc.)
- Authentication (OAuth2-proxy, Keycloak, etc.)
- Network policies (Calico, Cilium, etc.)
- Monitoring (Prometheus, Datadog, etc.)
- Backup (Velero, Kasten, etc.)
- GitOps (Flux CD, Argo CD, etc.)
- Service mesh (Linkerd, Istio, etc.) - optional

**Why this separation?**

- ✅ No vendor lock-in
- ✅ Use your existing tools
- ✅ Consistent with other apps in your cluster
- ✅ No "double authentication" or cert gymnastics
- ✅ Single source of truth for infrastructure config

---

## Common Integration Scenarios

### Scenario 1: Production Deployment with OAuth2 + Let's Encrypt

**What you need:**

1. Ingress controller (nginx/Traefik/etc.)
2. cert-manager with Let's Encrypt issuer
3. OAuth2-proxy deployment

**Integration:**

```yaml
# Your infrastructure (not in Ghostwire chart)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ghostwire
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/auth-url: "https://oauth2.example.com/oauth2/auth"
spec:
  tls:
  - hosts: [signal.company.com]
    secretName: ghostwire-tls  # cert-manager auto-creates this
  rules:
  - host: signal.company.com
    http:
      paths:
      - path: /
        backend:
          service:
            name: ghostwire  # Points to Ghostwire service
            port: {number: 6901}
```

**See:** [integration-examples.md](integration-examples.md#oauth2-letsencrypt) for complete example

### Scenario 2: Air-Gapped / Internal Network

**What you need:**

1. Internal CA or self-signed certs
2. Internal authentication (LDAP, SAML, etc.)
3. No external dependencies

**Integration:**

- Enable Ghostwire's built-in VNC auth: `auth.enabled=true`
- Use custom TLS: `tls.mode=custom`
- Deploy without external ingress

**See:** [integration-examples.md](integration-examples.md#air-gapped) for complete example

### Scenario 3: Service Mesh Integration

**What you need:**

1. Linkerd/Istio installed
2. Automatic mTLS between services
3. Observability via mesh

**Integration:**

```yaml
# Add mesh annotations (your infrastructure)
podAnnotations:
  linkerd.io/inject: enabled
  # OR for Istio:
  sidecar.istio.io/inject: "true"
```

**See:** [integration-patterns.md](integration-patterns.md#service-mesh) for mesh-specific patterns

---

## Architecture Diagram

```text
┌─────────────────────────────────────────────────────────────┐
│ Your Infrastructure Layer                                   │
│                                                              │
│  ┌──────────────┐  ┌────────────────┐  ┌─────────────────┐│
│  │   Ingress    │  │  OAuth2-Proxy  │  │  cert-manager   ││
│  │  Controller  │  │  (Keycloak)    │  │ (Let's Encrypt) ││
│  └──────┬───────┘  └────────┬───────┘  └────────┬────────┘│
│         │                   │                    │         │
│         │ TLS + Auth        │ OIDC Callback      │ Certs   │
│         └───────────────────┴────────────────────┘         │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ Ghostwire Chart (Application Layer)                         │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  StatefulSet: ghostwire-0                              │ │
│  │  ├─ Signal Desktop (Electron)                          │ │
│  │  ├─ KasmVNC Server (port 6901)                         │ │
│  │  └─ PersistentVolume (/home/kasm-user)                 │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Service: ghostwire (ClusterIP)                        │ │
│  │  └─ Port 6901 → StatefulSet                            │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

**Clean separation of concerns:**

- Ghostwire = Application runtime
- Your infrastructure = Routing, security, observability

---

## Next Steps

1. **Quick Start:** See [chart/README.md](../chart/README.md#quickstart)
2. **Production Patterns:** See [integration-patterns.md](integration-patterns.md)
3. **Examples:** See [integration-examples.md](integration-examples.md)
4. **Advanced Options:** See [infrastructure-layer-options.md](infrastructure-layer-options.md)

---

## Philosophy: Why Not Include Templates?

**Common question:** "Why not include optional ingress/networkpolicy templates in the chart?"

**Answer:**

- Every organization has **different** ingress controllers, auth providers, and security policies
- Including templates would require maintaining compatibility with dozens of tools
- Your infrastructure team already knows how to configure your ingress/auth/monitoring
- Ghostwire shouldn't make assumptions about your environment
- **Cloud-native principle:** Apps expose services, infrastructure handles routing/security

**Result:**

- ✅ Simpler, more focused chart
- ✅ No maintenance burden for tool-specific integrations
- ✅ Works with any infrastructure stack
- ✅ No "our way or the highway"

**This guide provides:**

- 📚 Integration patterns for common tools
- 📋 Ready-to-use examples you can customize
- 🎯 Clear boundaries between app and infrastructure

---

Last updated: October 2025
