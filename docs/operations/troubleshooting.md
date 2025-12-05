# Troubleshooting

Common issues and how to resolve them.

## Pod Won't Start

### Pending State

```bash
kubectl describe pod -n ghostwire ghostwire-0
```

**PVC not bound**: Check if the storage class exists and has available capacity.

```bash
kubectl get pvc -n ghostwire
kubectl get storageclass
```

**Insufficient resources**: The node may not have enough memory or CPU.

```bash
kubectl describe node <node-name> | grep -A5 "Allocated resources"
```

Reduce resource requests or add nodes to the cluster.

### CrashLoopBackOff

Check container logs:

```bash
kubectl logs -n ghostwire ghostwire-0 --previous
```

Common causes:

- **Memory pressure**: Signal Desktop runs out of memory. Increase the limit.
- **Corrupted data**: The Signal database is corrupted. May need to delete the PVC and re-link.
- **Image pull failure**: Check image availability and pull secrets.

## VNC Connection Issues

### Can't Connect

1. Verify the pod is running and ready:

```bash
kubectl get pods -n ghostwire
```

2. Check the service:

```bash
kubectl get svc -n ghostwire
```

3. Test direct connectivity:

```bash
kubectl port-forward -n ghostwire svc/ghostwire 6901:6901
# Then open http://localhost:6901
```

4. If using ingress, check ingress status:

```bash
kubectl describe ingress -n ghostwire ghostwire
```

### Black Screen

The X server is running but Signal Desktop may not have started.

```bash
# Check processes in the container
kubectl exec -n ghostwire ghostwire-0 -- ps aux
```

Look for `signal-desktop` in the process list. If missing, check logs for startup errors.

### Slow/Laggy

VNC performance depends on network latency and bandwidth.

- Reduce resolution: Set `VNC_RESOLUTION=1280x720` in environment
- Use a closer network path (avoid transcontinental connections)
- Ensure adequate bandwidth (VNC uses 1-5 Mbps depending on activity)

## Signal Desktop Issues

### Not Linked

If Signal Desktop shows the QR code linking screen after a pod restart, your data may have been lost.

Check PVC status:

```bash
kubectl get pvc -n ghostwire
kubectl describe pvc -n ghostwire <pvc-name>
```

If the PVC was deleted or replaced, you'll need to re-link with your phone.

### Can't Receive Messages

Signal Desktop requires an active connection to Signal's servers.

1. Check network egress:

```bash
kubectl exec -n ghostwire ghostwire-0 -- curl -v https://chat.signal.org
```

2. If using network policies, ensure egress to Signal servers is allowed (port 443).

3. Check if Signal is rate-limiting:

```bash
kubectl logs -n ghostwire ghostwire-0 | grep -i rate
```

### High Memory Usage

Signal Desktop memory grows with:
- Number of conversations
- Message history length
- Media attachments

If memory exceeds limits:

1. Increase the memory limit:

```bash
helm upgrade ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  --set resources.limits.memory=8Gi \
  -n ghostwire
```

2. Delete old conversations from within Signal Desktop

3. Consider clearing attachment cache (will re-download when viewed)

## Storage Issues

### PVC Full

Check usage:

```bash
kubectl exec -n ghostwire ghostwire-0 -- df -h /home/kasm-user
```

Expand the PVC if your storage class supports it:

```bash
helm upgrade ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  --set persistence.size=50Gi \
  -n ghostwire
```

### Data Corruption

SQLite corruption can occur from unclean shutdowns.

Symptoms:
- Signal Desktop won't start
- Errors mentioning "database malformed" in logs

Recovery options:

1. Restore from backup (see [Persistence](../guide/persistence.md))
2. Delete the PVC and re-link (loses message history)

```bash
# Delete and recreate
helm uninstall ghostwire -n ghostwire
kubectl delete pvc -l app.kubernetes.io/name=ghostwire -n ghostwire
helm install ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  --create-namespace -n ghostwire
```

## Authentication Issues

### OAuth2-Proxy Not Redirecting

Check OAuth2-Proxy logs:

```bash
kubectl logs -n ghostwire -l app=oauth2-proxy
```

Common causes:
- Incorrect redirect URI in identity provider configuration
- Cookie domain mismatch
- Invalid client credentials

### 403 After Authentication

The user may not be authorized. Check OAuth2-Proxy configuration:

- `--email-domain` restricts by email domain
- `--authenticated-emails-file` restricts to specific emails
- Identity provider may have group/role restrictions

## Upgrade Issues

### Helm Upgrade Fails

```bash
helm upgrade ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  -n ghostwire 2>&1 | tail -20
```

Common causes:
- Immutable field changed (need to uninstall and reinstall)
- Schema validation failure (check values against values.schema.json)
- Incompatible Kubernetes version

### Pod Stuck Terminating

Force deletion if graceful shutdown hangs:

```bash
kubectl delete pod ghostwire-0 -n ghostwire --grace-period=0 --force
```

## Getting Help

1. Check the [GitHub Discussions](https://github.com/drengskapur/ghostwire/discussions) for community help
2. Search [Issues](https://github.com/drengskapur/ghostwire/issues) for known problems
3. File a bug report with:
   - Kubernetes version
   - Helm chart version
   - Relevant logs
   - Steps to reproduce
