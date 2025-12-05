# Quick Start

This guide walks through your first Ghostwire deployment and linking Signal Desktop to your phone.

## Access the Desktop

After installation, access Signal Desktop via port-forward:

```bash
kubectl port-forward -n ghostwire svc/ghostwire 6901:6901
```

Open your browser to:

```
http://localhost:6901?keyboard=1
```

The `?keyboard=1` parameter enables the on-screen keyboard for QR code entry.

## Link Your Phone

Signal Desktop requires linking to an existing Signal account on your phone:

1. In the VNC browser session, Signal Desktop shows a QR code
2. On your phone, open Signal → Settings → Linked Devices → Link New Device
3. Scan the QR code displayed in the browser

Your message history will sync from your phone. This takes a few minutes depending on history size.

## Verify Persistence

Confirm your data persists across pod restarts:

```bash
# Delete the pod
kubectl delete pod -l app.kubernetes.io/name=ghostwire -n ghostwire

# Wait for replacement
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=ghostwire -n ghostwire --timeout=300s

# Access again - should show your linked account
kubectl port-forward -n ghostwire svc/ghostwire 6901:6901
```

Signal Desktop should still be linked with your message history intact.

## Production Access

Port-forwarding works for testing. For production, expose through ingress with proper authentication.

Basic ingress (no auth):

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

For authentication, see [Infrastructure Integration](../guide/infrastructure-integration.md).

## Keyboard Shortcuts

KasmVNC provides several useful shortcuts:

- **Ctrl+Alt+Shift** — Open control panel
- **F11** — Toggle fullscreen
- **Ctrl+Shift+V** — Paste from host clipboard

## Next Steps

- [Configuration](configuration.md) — Adjust resources and persistence
- [Infrastructure Integration](../guide/infrastructure-integration.md) — Add OAuth2, TLS, ingress
- [Troubleshooting](../operations/troubleshooting.md) — Debug common issues
