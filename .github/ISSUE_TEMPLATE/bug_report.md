---
name: Bug Report
about: Report a bug or unexpected behavior
title: '[BUG] '
labels: 'type: bug, status: needs-triage'
assignees: ''
---

## Bug Description

A clear and concise description of what the bug is.

## Steps to Reproduce

1. Deploy chart with...
2. Configure values...
3. Run command...
4. See error

## Expected Behavior

What you expected to happen.

## Actual Behavior

What actually happened.

## Environment

**Ghostwire Version:**
- Chart version: [e.g., 0.1.0]
- Image tag: [e.g., 1.18.0-rolling-daily]

**Kubernetes Environment:**
- Kubernetes version: [e.g., 1.28.0]
- Platform: [e.g., GKE, EKS, AKS, k3s, kind]
- Ingress controller: [e.g., nginx, traefik, istio]

**Deployment:**
- Namespace: [e.g., ghostwire]
- Helm values: [paste relevant values or attach values.yaml]

## Logs

<details>
<summary>Pod logs</summary>

```
kubectl logs -n ghostwire ghostwire-0
```

</details>

<details>
<summary>Pod describe</summary>

```
kubectl describe pod -n ghostwire ghostwire-0
```

</details>

## Additional Context

Add any other context about the problem here (screenshots, error messages, etc.).
