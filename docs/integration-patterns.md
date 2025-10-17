# Infrastructure Integration Patterns

Quick reference for integrating Ghostwire with your existing Kubernetes infrastructure.

## Ingress Integration

### nginx Ingress Controller

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ghostwire
  namespace: ghostwire
  annotations:
    # WebSocket support (required for VNC)
    nginx.ingress.kubernetes.io/websocket-services: "ghostwire"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
spec:
  ingressClassName: nginx
  rules:
  - host: signal.company.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ghostwire
            port:
              number: 6901
```

### Traefik Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ghostwire
  namespace: ghostwire
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
spec:
  ingressClassName: traefik
  rules:
  - host: signal.company.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ghostwire
            port:
              number: 6901
```

---

## TLS/Certificate Management

### cert-manager + Let's Encrypt

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ghostwire
  namespace: ghostwire
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - signal.company.com
    secretName: ghostwire-tls  # Auto-created by cert-manager
  rules:
  - host: signal.company.com
    # ... (rest of ingress config)
```

### Custom/External Certificates

```yaml
# Create secret with your certificate
kubectl create secret tls ghostwire-tls \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key \
  -n ghostwire

# Reference in ingress
spec:
  tls:
  - hosts:
    - signal.company.com
    secretName: ghostwire-tls
```

---

## Authentication Integration

### OAuth2-Proxy (Generic OIDC)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ghostwire
  namespace: ghostwire
  annotations:
    # OAuth2-proxy authentication
    nginx.ingress.kubernetes.io/auth-url: "https://oauth2.company.com/oauth2/auth"
    nginx.ingress.kubernetes.io/auth-signin: "https://oauth2.company.com/oauth2/start?rd=$scheme://$host$request_uri"
    nginx.ingress.kubernetes.io/auth-response-headers: "X-Auth-Request-User,X-Auth-Request-Email"

    # WebSocket support
    nginx.ingress.kubernetes.io/websocket-services: "ghostwire"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
spec:
  # ... (rest of config)
```

### Authentik

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ghostwire
  namespace: ghostwire
  annotations:
    nginx.ingress.kubernetes.io/auth-url: "https://authentik.company.com/outpost.goauthentik.io/auth/nginx"
    nginx.ingress.kubernetes.io/auth-signin: "https://authentik.company.com/outpost.goauthentik.io/start?rd=$escaped_request_uri"
    nginx.ingress.kubernetes.io/auth-response-headers: "Set-Cookie,X-authentik-username,X-authentik-groups,X-authentik-email"
    nginx.ingress.kubernetes.io/auth-snippet: |
      proxy_set_header X-Forwarded-Host $http_host;
spec:
  # ... (rest of config)
```

### Keycloak

Deploy OAuth2-proxy configured for Keycloak:

```yaml
# OAuth2-proxy deployment pointing to Keycloak
env:
- name: OAUTH2_PROXY_PROVIDER
  value: "keycloak-oidc"
- name: OAUTH2_PROXY_OIDC_ISSUER_URL
  value: "https://keycloak.company.com/realms/your-realm"
- name: OAUTH2_PROXY_CLIENT_ID
  value: "ghostwire"
- name: OAUTH2_PROXY_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: oauth2-proxy-secrets
      key: client-secret
```

---

## Network Policies

### Basic Ingress Isolation

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ghostwire-ingress
  namespace: ghostwire
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: ghostwire
  policyTypes:
  - Ingress
  ingress:
  # Allow from ingress controller
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 6901
```

### Complete Network Isolation

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ghostwire-complete
  namespace: ghostwire
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: ghostwire
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Allow from ingress controller
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 6901
  egress:
  # Allow DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  # Allow internet (Signal Desktop needs external connectivity)
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
```

---

## Service Mesh Integration

### Linkerd

```yaml
# Add to Ghostwire chart values
podAnnotations:
  linkerd.io/inject: enabled
  config.linkerd.io/proxy-cpu-request: "100m"
  config.linkerd.io/proxy-memory-request: "128Mi"
```

### Istio

```yaml
# Add to Ghostwire chart values
podAnnotations:
  sidecar.istio.io/inject: "true"
  traffic.sidecar.istio.io/includeInboundPorts: "6901"
```

### Service Mesh VirtualService (Istio)

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: ghostwire
  namespace: ghostwire
spec:
  hosts:
  - signal.company.com
  gateways:
  - istio-system/default-gateway
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: ghostwire.ghostwire.svc.cluster.local
        port:
          number: 6901
    timeout: 3600s  # Long timeout for VNC sessions
    websocketUpgrade: true
```

---

## Monitoring & Observability

### Prometheus (if KasmVNC adds metrics)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: ghostwire
  namespace: ghostwire
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: ghostwire
  endpoints:
  - port: metrics
    interval: 30s
```

**Note:** KasmVNC doesn't currently expose Prometheus metrics. Monitor via:
- Ingress controller metrics (request latency, errors)
- Kubernetes metrics (CPU, memory, pod restarts)
- Service mesh metrics (if using Linkerd/Istio)

### Grafana Dashboard

Use Kubernetes monitoring dashboards:
- Pod resource usage (CPU/memory)
- Network traffic (service mesh)
- Storage (PVC usage)

---

## Backup & Disaster Recovery

### Velero

```bash
# Backup entire namespace
velero backup create ghostwire-backup --include-namespaces ghostwire

# Backup with PVC snapshots
velero backup create ghostwire-full \
  --include-namespaces ghostwire \
  --snapshot-volumes
```

### Kasten K10

```yaml
apiVersion: config.kio.kasten.io/v1alpha1
kind: Policy
metadata:
  name: ghostwire-backup
  namespace: ghostwire
spec:
  frequency: "@daily"
  retention:
    daily: 7
    weekly: 4
    monthly: 12
  selector:
    matchLabels:
      app.kubernetes.io/name: ghostwire
  actions:
  - action: backup
```

### Manual Backup (kubectl)

```bash
# Backup PVC data
kubectl exec -n ghostwire ghostwire-0 -- \
  tar czf - /home/kasm-user | \
  gzip > ghostwire-signal-data-$(date +%Y%m%d).tar.gz
```

---

## GitOps Integration

### Flux CD HelmRelease

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: ghostwire
  namespace: ghostwire
spec:
  interval: 10m
  chart:
    spec:
      chart: ./chart
      sourceRef:
        kind: GitRepository
        name: ghostwire
        namespace: flux-system
  values:
    image:
      tag: "1.18.0-rolling-daily"
    persistence:
      enabled: true
      size: 20Gi
    resources:
      limits:
        memory: 4Gi
      requests:
        memory: 1Gi
  test:
    enable: true
  upgrade:
    remediation:
      retries: 3
      remediateLastFailure: true
```

### Argo CD Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ghostwire
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourorg/ghostwire
    targetRevision: main
    path: chart
    helm:
      values: |
        persistence:
          enabled: true
          size: 20Gi
  destination:
    server: https://kubernetes.default.svc
    namespace: ghostwire
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

---

## Additional Integrations

### Pod Disruption Budget

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: ghostwire
  namespace: ghostwire
spec:
  maxUnavailable: 0  # Never disrupt (single replica)
  selector:
    matchLabels:
      app.kubernetes.io/name: ghostwire
```

### Priority Class

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: ghostwire-priority
value: 1000
description: "Priority for Ghostwire StatefulSet"
---
# Reference in chart values
priorityClassName: ghostwire-priority
```

---

*See also:*
- [infrastructure-integration-guide.md](infrastructure-integration-guide.md) for overview
- [Chart README](../chart/README.md) for configuration options
- [Deployment Strategies](deployment-strategies.md) for architecture details
