---
title: Security Model - Ghostwire Container Security
description: Ghostwire security architecture with container isolation, RBAC, network policies, and OAuth2 integration. Non-root containers, seccomp profiles, and encryption.
---

# Security Model

Ghostwire's security relies on defense in depth: container isolation, Kubernetes RBAC, network policies, and infrastructure-level authentication.

## Trust Boundaries

### Container Isolation

The container runs as a non-root user (`kasm-user`, UID 1000). Security contexts in the Helm chart:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  capabilities:
    drop:
      - ALL
```

Signal Desktop's Chromium sandbox is disabled (`--no-sandbox`) because the container itself provides the isolation boundary. This is standard practice for containerized Electron applications.

### Kubernetes RBAC

The chart creates minimal RBAC:

- A ServiceAccount for the pod
- No cluster-level permissions
- No access to Kubernetes API beyond default

The pod only accesses its own PVC and the network.

### Network Exposure

By default, the Service is ClusterIP—no external access without explicit ingress configuration.

**Warning**: Port 6901 (VNC) has no authentication by default. Anyone who can reach the Service can access Signal Desktop.

## Authentication Options

### Infrastructure Authentication (Recommended)

Route traffic through an authenticating proxy:

- OAuth2-Proxy with your identity provider (Google, GitHub, Azure AD, etc.)
- Keycloak or Authentik for more complex requirements
- Your ingress controller's built-in auth annotations

See [Infrastructure Integration](../guide/infrastructure-integration.md) for examples.

### VNC Password (Basic)

The Kasm container supports native VNC password authentication:

```yaml
env:
  - name: VNC_PW
    valueFrom:
      secretKeyRef:
        name: ghostwire-vnc
        key: password
```

This provides basic protection but:
- Shared password (not per-user)
- No audit trail
- Password transmitted with VNC (use TLS)

Only use this as a secondary layer, not primary authentication.

## TLS Configuration

### Ingress TLS (Recommended)

Terminate TLS at the ingress layer:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
    - hosts:
        - signal.example.com
      secretName: ghostwire-tls
```

Traffic from ingress to the pod is unencrypted. This is standard for cluster-internal traffic. If you need end-to-end encryption, use a service mesh.

### Service Mesh mTLS

For encrypted pod-to-pod traffic:

```yaml
# Linkerd
podAnnotations:
  linkerd.io/inject: enabled

# Istio
podAnnotations:
  sidecar.istio.io/inject: "true"
```

The mesh provides automatic mTLS between all participating services.

## Data Security

### Encryption at Rest

Signal Desktop encrypts messages at the application layer using keys stored in `~/.config/Signal/`. The underlying storage (PVC) may or may not be encrypted depending on your storage class.

For additional protection:
- Use encrypted storage classes if available
- Enable Kubernetes secrets encryption at rest
- Consider encrypting the entire PVC with solutions like LUKS

### Encryption in Transit

| Path | Encryption |
|------|------------|
| Browser → Ingress | TLS (via cert-manager) |
| Ingress → Pod | Unencrypted (or mTLS via service mesh) |
| Signal Desktop → Signal servers | TLS + Signal Protocol |

Signal's end-to-end encryption is independent of transport security—messages are encrypted before leaving the application.

## Network Policies

Restrict traffic to the namespace:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ghostwire-default-deny
  namespace: ghostwire
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ghostwire-allow-ingress
  namespace: ghostwire
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
        - port: 6901
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ghostwire-allow-egress
  namespace: ghostwire
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: ghostwire
  policyTypes:
    - Egress
  egress:
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
      ports:
        - port: 443  # Signal servers
        - port: 53   # DNS
          protocol: UDP
```

## Pod Security Standards

The chart is compatible with Kubernetes Pod Security Standards at the `restricted` level with minor adjustments (the container runs as non-root UID 1000).

## Secrets Management

Avoid hardcoding secrets in values files. Use:

- Kubernetes Secrets with external secrets operator
- HashiCorp Vault
- Cloud provider secret managers (AWS Secrets Manager, GCP Secret Manager)

Example with External Secrets:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: ghostwire-vnc
  namespace: ghostwire
spec:
  secretStoreRef:
    name: vault
    kind: ClusterSecretStore
  target:
    name: ghostwire-vnc
  data:
    - secretKey: password
      remoteRef:
        key: ghostwire/vnc
        property: password
```

## Audit Considerations

The container doesn't produce structured audit logs. For audit requirements:

- Use ingress access logs for connection records
- Enable Kubernetes audit logging for API access
- Consider a sidecar for application-level logging if needed

Signal Desktop itself logs to stdout/stderr, captured by Kubernetes logging.
