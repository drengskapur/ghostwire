# Ghostwire

Helm chart for running [Signal Desktop](https://signal.org/) in Kubernetes with persistent storage and web-based access.

## Design Philosophy: Cloud-Native Security

**This chart is designed to run without built-in authentication or TLS by default.**

Why? Because in cloud-native environments, authentication and encryption should be handled by infrastructure, not by individual applications:

✅ **Use Kubernetes Ingress** with TLS termination (cert-manager + Let's Encrypt)
✅ **Use OAuth2 Proxy** or similar for authentication (Google, GitHub, etc.)
✅ **Use Service Mesh** (Istio, Linkerd) for mTLS between services
✅ **Use Network Policies** to restrict pod-to-pod communication

**Benefits of this approach:**
- **Single Sign-On** - Users authenticate once at the ingress, not twice (no double-auth)
- **Standard Tooling** - Use industry-standard cert-manager, OAuth2-proxy, etc.
- **Better UX** - No managing/rotating VNC passwords
- **Centralized Control** - All auth/TLS configuration in one place
- **No Cert Gymnastics** - Don't need to inject custom certs into VNC pods
- **Observability** - Centralized auth logs and metrics at ingress

**Example Production Setup:**
```yaml
# Ingress with TLS + OAuth2
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ghostwire
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/auth-url: "https://oauth2.example.com/oauth2/auth"
spec:
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

With this setup, Ghostwire runs with `auth.enabled: false` and `tls.mode: disabled`, while the ingress handles TLS termination and OAuth2 authentication.

**When to use built-in auth/TLS:**
- Local development and testing
- Air-gapped environments without ingress infrastructure
- Quick demos and POCs

For production, let Kubernetes infrastructure handle security.

---

## TL;DR

```bash
helm install ghostwire ./chart --create-namespace -n ghostwire
kubectl port-forward -n ghostwire svc/ghostwire 6901:6901
# Open http://localhost:6901?keyboard=1
```

## What is this?

Ghostwire deploys Signal Desktop in a browser-accessible VNC session with:

- **Persistent storage** - Your conversations survive pod restarts
- **StatefulSet** - Stable identity for Signal's device linking
- **Web-based VNC** - Access via KasmVNC (no VNC client needed)
- **On-screen keyboard** - Mobile-friendly input support

## Installation

### From source

```bash
helm install ghostwire ./chart \
  --create-namespace \
  --namespace ghostwire \
  --set auth.password=your-secure-password
```

### With custom configuration

```yaml
# values-custom.yaml
auth:
  password: "change-me"

resources:
  requests:
    memory: "2Gi"
    cpu: "500m"
  limits:
    memory: "4Gi"
    cpu: "2000m"

persistence:
  size: 10Gi
  storageClass: "fast-ssd"
```

```bash
helm install ghostwire ./chart -f values-custom.yaml -n ghostwire
```

## Accessing Signal

After installation, follow the NOTES output. For ClusterIP (default):

```bash
kubectl port-forward -n ghostwire svc/ghostwire 6901:6901
```

Then open: **http://localhost:6901?keyboard=1**

**First-time setup:**
1. Open Signal Desktop in the VNC session
2. Scan the QR code with your phone's Signal app
3. Link your device as "Ghostwire" or similar

## Configuration

Key values to customize (see [values.yaml](values.yaml) for all options):

| Parameter | Description | Default |
|-----------|-------------|---------|
| `auth.password` | VNC password (required if auth enabled) | `testpass123` |
| `auth.enabled` | Enable VNC authentication | `true` |
| `persistence.size` | Signal data volume size | `5Gi` |
| `persistence.storageClass` | StorageClass for PVC | `""` (default) |
| `resources.requests.memory` | Minimum memory | `1Gi` |
| `resources.limits.memory` | Maximum memory | `2Gi` |
| `display.resolution` | VNC screen resolution | `1280x720` |
| `service.type` | Service type (ClusterIP/NodePort/LoadBalancer) | `ClusterIP` |

## Common tasks

### View logs
```bash
kubectl logs -n ghostwire ghostwire-0 -f
```

### Check pod status
```bash
kubectl get pod -n ghostwire ghostwire-0
kubectl describe pod -n ghostwire ghostwire-0
```

### Access the persistent volume
```bash
kubectl exec -n ghostwire ghostwire-0 -- ls -la /home/kasm-user/.config/Signal
```

### Change VNC password
```bash
helm upgrade ghostwire ./chart -n ghostwire --set auth.password=new-password --reuse-values
```

### Increase storage size
```bash
# Edit the PVC (if supported by your storage class)
kubectl patch pvc -n ghostwire ghostwire-ghostwire-0 -p '{"spec":{"resources":{"requests":{"storage":"10Gi"}}}}'
```

## Security considerations

- **Change the default password** - `auth.password` defaults to `testpass123`
- **Use authentication** - Keep `auth.enabled: true` in production
- **Network policies** - Consider adding NetworkPolicies to restrict access
- **TLS** - Use an ingress with TLS termination for external access
- **Resource limits** - Set appropriate limits to prevent resource exhaustion

## Troubleshooting

### Signal won't start
Check pod logs for errors:
```bash
kubectl logs -n ghostwire ghostwire-0 | grep -i error
```

### VNC shows blank screen
1. Check if the pod is running: `kubectl get pod -n ghostwire`
2. Verify resources: `kubectl top pod -n ghostwire ghostwire-0`
3. Increase `shmSize` if browser crashes (default: 512MB)

### Authentication fails
Browsers cache VNC credentials. To reset:
- Use an incognito/private window, or
- Clear browser data (Ctrl+Shift+Delete)

### Persistent data loss
Check PVC status:
```bash
kubectl get pvc -n ghostwire
kubectl describe pvc -n ghostwire ghostwire-ghostwire-0
```

## Uninstallation

```bash
# Remove the release
helm uninstall ghostwire -n ghostwire

# Delete the PVC (WARNING: This deletes your Signal data!)
kubectl delete pvc -n ghostwire ghostwire-ghostwire-0

# Delete the namespace
kubectl delete namespace ghostwire
```

## License

This chart is licensed under the MIT License. Signal Desktop is licensed under the AGPLv3.
