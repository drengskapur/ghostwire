# Persistence

Signal Desktop stores messages, encryption keys, and media on disk. Ghostwire uses a PersistentVolumeClaim to ensure this data survives pod restarts.

## What Gets Stored

The container user home directory (`/home/kasm-user`) contains:

- `~/.config/Signal/` — Application configuration and encryption keys
- `~/.local/share/Signal/` — SQLite message database and attachments

The PVC mounts at `/home/kasm-user` to capture the entire user directory.

## Default Configuration

```yaml
persistence:
  enabled: true
  size: 10Gi
  accessMode: ReadWriteOnce
  # storageClass: ""  # Uses cluster default
  mountPath: /home/kasm-user
```

The default 10Gi is sufficient for typical usage. If you exchange a lot of media, increase the size.

## Storage Class Selection

Most managed Kubernetes services provide a default storage class. For production, you may want to specify one explicitly:

```bash
# List available storage classes
kubectl get storageclass

# Specify in Helm values
helm upgrade ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  --set persistence.storageClass=premium-ssd \
  -n ghostwire
```

Consider:

- **SSD-backed storage** for better performance (Signal Desktop does frequent database writes)
- **Retention policy** — some storage classes delete the underlying volume when the PVC is deleted

## Resizing

Many storage providers support volume expansion. If you need more space:

```bash
# Check if storage class allows expansion
kubectl get storageclass <name> -o jsonpath='{.allowVolumeExpansion}'

# If true, just update the PVC size
helm upgrade ghostwire oci://ghcr.io/drengskapur/charts/ghostwire \
  --set persistence.size=50Gi \
  -n ghostwire
```

The volume expands without data loss. The pod may need to restart for the filesystem to recognize the new size.

## Backup Strategies

### Velero

Velero can snapshot PVCs on supported storage providers:

```yaml
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: ghostwire-daily
  namespace: velero
spec:
  schedule: "0 3 * * *"
  template:
    includedNamespaces:
      - ghostwire
    includedResources:
      - persistentvolumeclaims
```

### Manual Snapshot

For cloud providers with snapshot APIs:

```bash
# AWS EBS
aws ec2 create-snapshot --volume-id <volume-id> --description "ghostwire backup"

# GCP
gcloud compute disks snapshot <disk-name> --zone=<zone>
```

### File-Level Backup

If volume snapshots aren't available, copy files to external storage:

```bash
# Create a backup job
kubectl create job signal-backup --image=busybox -n ghostwire -- \
  tar czf /backup/signal-$(date +%Y%m%d).tar.gz -C /data .
```

Mount both the Signal PVC and a backup PVC to the job.

## Encryption

Signal Desktop encrypts messages with keys stored in `~/.config/Signal/`. The database is not encrypted at the filesystem level—encryption happens at the application layer.

For additional protection:

- Use encrypted storage classes if your provider offers them
- Enable Kubernetes secrets encryption at rest
- Consider network-level encryption (mTLS via service mesh)

## Data Loss Scenarios

### PVC Deleted

If the PVC is deleted, Signal Desktop starts fresh. You'll need to re-link with your phone and message history won't sync (Signal doesn't store message history on servers).

**Prevention**: Use `helm uninstall` carefully—the default behavior retains PVCs. Explicitly delete PVCs only when you intend to lose the data.

### Storage Provider Failure

If the underlying storage fails, data may be unrecoverable.

**Prevention**: Regular backups to a separate storage system. For critical deployments, use storage with built-in replication.

### Corrupted Database

SQLite corruption is rare but possible (power loss during writes, storage hardware issues).

**Recovery**: Restore from backup. Signal Desktop may be able to re-sync some recent messages from your phone, but older messages are lost if not backed up.

## Multi-Cluster Considerations

PVCs are bound to a single cluster. If you need Signal Desktop in multiple clusters:

- Each cluster has its own instance with its own PVC
- You can only link one Signal Desktop instance per phone number at a time
- Switching clusters means re-linking (your old session becomes disconnected)

There's no supported way to share a Signal Desktop session across clusters.
