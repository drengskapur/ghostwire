# Infrastructure Integration

Ghostwire delegates infrastructure concerns to your existing Kubernetes platform. This guide shows how to integrate with common infrastructure components.

## Design Rationale

The chart doesn't include ingress templates, authentication configuration, or TLS settings. Why?

Every organization has different ingress controllers, identity providers, and security policies. Including templates would require maintaining compatibility with dozens of tools and would inevitably conflict with your existing configuration.

Instead, the chart exposes a ClusterIP Service. You route to it using whatever infrastructure you already run.

## Ingress

### nginx Ingress Controller

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ghostwire
  namespace: ghostwire
  annotations:
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
spec:
  ingressClassName: nginx
  rules:
    - host: signal.example.com
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

The timeout annotations are important for VNC—connections are long-lived.

### Traefik

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ghostwire
  namespace: ghostwire
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
spec:
  rules:
    - host: signal.example.com
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

## TLS with cert-manager

Add TLS termination using cert-manager and Let's Encrypt:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ghostwire
  namespace: ghostwire
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - signal.example.com
      secretName: ghostwire-tls
  rules:
    - host: signal.example.com
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

cert-manager will automatically provision and renew the certificate.

## Authentication with OAuth2-Proxy

VNC access is unprotected by default. For production, add authentication at the ingress layer.

### Deploy OAuth2-Proxy

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: oauth2-proxy
  namespace: ghostwire
spec:
  replicas: 1
  selector:
    matchLabels:
      app: oauth2-proxy
  template:
    metadata:
      labels:
        app: oauth2-proxy
    spec:
      containers:
        - name: oauth2-proxy
          image: quay.io/oauth2-proxy/oauth2-proxy:v7.5.1
          args:
            - --provider=google  # or github, azure, etc.
            - --upstream=http://ghostwire:6901
            - --http-address=0.0.0.0:4180
            - --email-domain=example.com
            - --cookie-secure=true
          env:
            - name: OAUTH2_PROXY_CLIENT_ID
              valueFrom:
                secretKeyRef:
                  name: oauth2-proxy
                  key: client-id
            - name: OAUTH2_PROXY_CLIENT_SECRET
              valueFrom:
                secretKeyRef:
                  name: oauth2-proxy
                  key: client-secret
            - name: OAUTH2_PROXY_COOKIE_SECRET
              valueFrom:
                secretKeyRef:
                  name: oauth2-proxy
                  key: cookie-secret
          ports:
            - containerPort: 4180
---
apiVersion: v1
kind: Service
metadata:
  name: oauth2-proxy
  namespace: ghostwire
spec:
  selector:
    app: oauth2-proxy
  ports:
    - port: 4180
```

### Route Ingress Through OAuth2-Proxy

Point the ingress at OAuth2-Proxy instead of Ghostwire directly:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ghostwire
  namespace: ghostwire
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - signal.example.com
      secretName: ghostwire-tls
  rules:
    - host: signal.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: oauth2-proxy
                port:
                  number: 4180
```

Now users must authenticate through your identity provider before accessing Signal Desktop.

## Network Policies

Restrict traffic to the Ghostwire namespace:

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
    - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx  # Only allow from ingress namespace
      ports:
        - protocol: TCP
          port: 6901
```

## Monitoring

If you're using Prometheus, add a ServiceMonitor:

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
    - port: http
      interval: 30s
```

Note: The Kasm container doesn't expose Prometheus metrics natively. You may need a sidecar exporter for detailed application metrics.

## Backup with Velero

Back up the Signal data PVC:

```yaml
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: ghostwire-backup
  namespace: velero
spec:
  schedule: "0 2 * * *"  # Daily at 2am
  template:
    includedNamespaces:
      - ghostwire
    includedResources:
      - persistentvolumeclaims
      - persistentvolumes
    storageLocation: default
    ttl: 720h  # 30 days
```

## Service Mesh

For Linkerd:

```yaml
# In your Helm values
podAnnotations:
  linkerd.io/inject: enabled
```

For Istio:

```yaml
podAnnotations:
  sidecar.istio.io/inject: "true"
```

The service mesh provides mTLS between services automatically.
