# Monitoring

Ghostwire's health can be monitored through Kubernetes probes, resource metrics, and external observability tools.

## Health Probes

The Helm chart configures liveness and readiness probes:

```yaml
livenessProbe:
  tcpSocket:
    port: 6901
  initialDelaySeconds: 60
  periodSeconds: 30
  failureThreshold: 3

readinessProbe:
  tcpSocket:
    port: 6901
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 5
```

These check TCP connectivity to the VNC port. The pod is considered unhealthy if:
- VNC server stops responding
- Signal Desktop crashes and takes down the X server
- Resource exhaustion prevents connections

## Resource Metrics

Monitor pod resource consumption:

```bash
# Current resource usage
kubectl top pod -n ghostwire

# Watch over time
kubectl top pod -n ghostwire --watch
```

Key metrics to watch:

| Metric | Normal Range | Alert Threshold |
|--------|--------------|-----------------|
| Memory | 700MB - 1.5GB | > 3GB |
| CPU | 10-30% | > 80% sustained |
| Network TX | Varies with usage | Unusual spikes |

## Prometheus Integration

If you're running Prometheus, create a ServiceMonitor:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: ghostwire
  namespace: ghostwire
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: ghostwire
  namespaceSelector:
    matchNames:
      - ghostwire
  endpoints:
    - port: http
      interval: 30s
```

Note: The Kasm container doesn't expose Prometheus metrics natively. You'll get basic service discovery but no application-specific metrics without additional instrumentation.

### kube-state-metrics

Standard Kubernetes metrics are available through kube-state-metrics:

```promql
# Pod restarts
kube_pod_container_status_restarts_total{namespace="ghostwire"}

# Pod phase
kube_pod_status_phase{namespace="ghostwire"}

# Container resource requests vs usage
container_memory_usage_bytes{namespace="ghostwire"}
  / on(pod) kube_pod_container_resource_requests{namespace="ghostwire", resource="memory"}
```

### Alerting Rules

Example PrometheusRule:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: ghostwire-alerts
  namespace: ghostwire
spec:
  groups:
    - name: ghostwire
      rules:
        - alert: GhostwirePodNotReady
          expr: |
            kube_pod_status_ready{namespace="ghostwire", condition="true"} == 0
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "Ghostwire pod not ready"
            description: "Pod {{ $labels.pod }} has been not ready for 5 minutes"

        - alert: GhostwireHighMemory
          expr: |
            container_memory_usage_bytes{namespace="ghostwire", container="ghostwire"}
              / container_spec_memory_limit_bytes{namespace="ghostwire", container="ghostwire"}
              > 0.9
          for: 10m
          labels:
            severity: warning
          annotations:
            summary: "Ghostwire memory usage high"
            description: "Memory usage above 90% for 10 minutes"

        - alert: GhostwireRestarting
          expr: |
            increase(kube_pod_container_status_restarts_total{namespace="ghostwire"}[1h]) > 3
          labels:
            severity: warning
          annotations:
            summary: "Ghostwire pod restarting frequently"
            description: "Pod has restarted {{ $value }} times in the last hour"
```

## Logging

Container logs go to stdout/stderr:

```bash
# View logs
kubectl logs -n ghostwire statefulset/ghostwire

# Follow logs
kubectl logs -n ghostwire statefulset/ghostwire -f

# Previous container (if restarted)
kubectl logs -n ghostwire statefulset/ghostwire --previous
```

Log aggregation with Loki, Elasticsearch, or your preferred solution works with standard Kubernetes log collection.

### Log Content

The container logs contain:
- Xvnc connection events
- XFCE session messages
- Signal Desktop console output
- Error messages and stack traces

Signal Desktop logs are verbose at startup but quiet during normal operation.

## Dashboard

Grafana dashboard for Ghostwire:

```json
{
  "title": "Ghostwire",
  "panels": [
    {
      "title": "Pod Status",
      "type": "stat",
      "targets": [
        {
          "expr": "kube_pod_status_ready{namespace='ghostwire', condition='true'}"
        }
      ]
    },
    {
      "title": "Memory Usage",
      "type": "timeseries",
      "targets": [
        {
          "expr": "container_memory_usage_bytes{namespace='ghostwire', container='ghostwire'}"
        }
      ]
    },
    {
      "title": "CPU Usage",
      "type": "timeseries",
      "targets": [
        {
          "expr": "rate(container_cpu_usage_seconds_total{namespace='ghostwire', container='ghostwire'}[5m])"
        }
      ]
    },
    {
      "title": "Restarts",
      "type": "stat",
      "targets": [
        {
          "expr": "kube_pod_container_status_restarts_total{namespace='ghostwire'}"
        }
      ]
    }
  ]
}
```

## Uptime Monitoring

External uptime checks can verify accessibility:

```yaml
# UptimeRobot, Pingdom, or similar
type: HTTP
url: https://signal.example.com/
method: GET
expected_status: 200  # or 401 if behind auth
interval: 60s
```

Note: The VNC endpoint returns an HTML page, not a health check endpoint. Check for HTTP 200 (or 401/302 if behind authentication).
