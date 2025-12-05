# Contributing

Ghostwire welcomes contributions. This guide covers development setup and expectations for pull requests.

## Development Setup

### Prerequisites

- Kubernetes cluster (k3d, kind, minikube, or remote)
- Helm 3.x
- kubectl configured for your cluster
- Task (optional, for running Taskfile commands)

### Local Testing

```bash
# Create a local cluster
k3d cluster create ghostwire

# Install the chart from local source
helm install ghostwire ./chart \
  --create-namespace -n ghostwire

# Port-forward to test
kubectl port-forward -n ghostwire svc/ghostwire 6901:6901
```

### Making Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Make changes
4. Test locally
5. Commit with conventional commits: `git commit -m "feat: add new capability"`
6. Push and open a pull request

## Code Structure

```
ghostwire/
├── chart/                 # Helm chart
│   ├── templates/        # Kubernetes manifests
│   ├── values.yaml       # Default values
│   ├── values.schema.json # Value validation schema
│   └── Chart.yaml        # Chart metadata
├── docs/                  # Documentation
├── .github/              # GitHub workflows
│   └── workflows/        # CI/CD pipelines
└── scripts/              # Utility scripts
```

## Pull Request Guidelines

### Size

Keep pull requests focused. A PR should do one thing well. Large changes are harder to review and more likely to introduce bugs.

### Testing

Test your changes:

1. Lint the chart:

```bash
helm lint ./chart
```

2. Template validation:

```bash
helm template ghostwire ./chart | kubectl apply --dry-run=client -f -
```

3. Deploy and verify functionality

### Documentation

If your change affects user-facing behavior:
- Update relevant documentation
- Update `values.yaml` comments if changing values
- Update `values.schema.json` if adding or modifying values

### Commit Messages

Use conventional commits:

```
feat: add resource quota support
fix: correct memory limit calculation
docs: update installation guide
chore: update dependencies
```

The message should describe what the change accomplishes, not how.

## Chart Development

### Adding a Value

1. Add to `values.yaml` with documentation comment
2. Add schema entry in `values.schema.json`
3. Reference in templates with `{{ .Values.newValue }}`
4. Document in chart README

### Modifying Templates

Templates are Go templates with Helm/Sprig functions. Test rendering:

```bash
helm template ghostwire ./chart --debug
```

Use `helm template --set` to test different value combinations.

### Schema Validation

The chart includes a JSON schema for value validation:

```bash
# Validate values against schema
helm lint ./chart -f custom-values.yaml
```

IDEs with YAML schema support will provide autocomplete and validation.

## Looking for Co-Maintainers

This project is actively seeking additional maintainers. If you're interested in:
- Reviewing pull requests
- Triaging issues
- Feature development
- Documentation improvements

Please reach out via [GitHub Discussions](https://github.com/drengskapur/ghostwire/discussions).

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.
