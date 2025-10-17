# Ghostwire

**Cloud-Native Signal Desktop for Kubernetes** - Browser-based access with infrastructure-level security.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Helm](https://img.shields.io/badge/Helm-v3-blue)](https://helm.sh)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.25%2B-blue)](https://kubernetes.io)

Run Signal Desktop in your Kubernetes cluster with persistent storage, OAuth2 authentication, and cloud-native security.

---

## ✨ Features

- **🔐 Infrastructure-Level Security** - OAuth2, cert-manager, service mesh integration
- **💾 Persistent Storage** - Conversations survive pod restarts (StatefulSet + PVC)
- **🌐 Browser Access** - No VNC client needed (KasmVNC web client)
- **📱 Mobile-Friendly** - On-screen keyboard support
- **☁️ Cloud-Native** - Leverages platform capabilities instead of reinventing them

---

## 🚀 Quickstart

Get Signal Desktop running in 60 seconds:

```bash
# Install
helm install ghostwire ./chart --create-namespace -n ghostwire

# Access locally
kubectl port-forward -n ghostwire svc/ghostwire 6901:6901

# Open in browser
open http://localhost:6901?keyboard=1
```

**Default credentials** (when auth is enabled):
- Username: `kasm_user`
- Password: `CorrectHorseBatteryStaple`

⚠️ **For production:** Use ingress + OAuth2 instead → [Production Setup](chart/README.md#production-setup)

---

## 📖 Documentation

- **[Helm Chart README](chart/README.md)** - Complete installation and configuration guide
- **[Container Architecture](docs/container-architecture.md)** - Deep dive into runtime internals
- **[Deployment Strategies](docs/deployment-strategies.md)** - Why StatefulSet, rollout strategies
- **[Infrastructure Integration](docs/infrastructure-integration-guide.md)** - Cloud-native patterns

---

## 🎯 Why Ghostwire?

Unlike traditional VNC deployments that bake security into the application, **Ghostwire is designed as a well-behaved cloud-native citizen** that integrates with your existing Kubernetes infrastructure.

### The Cloud-Native Difference

**Traditional Approach:**
- ❌ VNC password → manage/rotate credentials per app
- ❌ Self-signed certs → browser warnings
- ❌ Double authentication → login twice
- ❌ Per-app TLS config → certificate gymnastics

**Ghostwire's Approach:**
- ✅ No built-in auth → use OAuth2/OIDC provider
- ✅ No built-in TLS → cert-manager + Let's Encrypt
- ✅ Single sign-on → authenticate once
- ✅ Infrastructure security → network policies, service mesh

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Your Infrastructure Layer                                   │
│  Ingress (TLS) + OAuth2 + cert-manager + Network Policies   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ Ghostwire (Application Layer)                               │
│  StatefulSet → Service → PersistentVolume                   │
│  Signal Desktop + KasmVNC + XFCE                            │
└─────────────────────────────────────────────────────────────┘
```

**Clean separation:** Ghostwire handles the application, your infrastructure handles routing/security/observability.

---

## 🔧 Configuration

Helm chart with 60+ configurable parameters:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `auth.enabled` | `false` | Auth at ingress (OAuth2) |
| `tls.mode` | `disabled` | TLS at ingress (cert-manager) |
| `persistence.size` | `10Gi` | Signal data storage |
| `resources.limits.memory` | `4Gi` | Maximum memory |

See [values.yaml](chart/values.yaml) for complete reference.

---

## 🤝 Contributing

Contributions welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Development setup
- Testing requirements
- Commit conventions
- Pull request process

---

## 📄 License

- **This Helm chart**: [Apache License 2.0](LICENSE)
- **Signal Desktop**: AGPLv3 ([Signal Messenger LLC](https://signal.org))
- **Kasm Workspaces**: MIT License ([Kasm Technologies Inc](https://kasmweb.com))

See [NOTICE](NOTICE) for complete third-party attributions.

---

## 🙏 Acknowledgments

Built with:
- [Signal Desktop](https://github.com/signalapp/Signal-Desktop) - Secure messaging application
- [Kasm Workspaces](https://github.com/kasmtech/workspaces-images) - Container streaming platform
- [KasmVNC](https://github.com/kasmtech/KasmVNC) - Modern VNC server with web client
- [XFCE](https://xfce.org/) - Lightweight desktop environment

Signal Messenger LLC and Kasm Technologies Inc do not endorse or support this project.

---

## 💬 Support

- 📚 **Documentation**: [chart/README.md](chart/README.md)
- 🐛 **Issues**: [GitHub Issues](https://github.com/drengskapur/ghostwire/issues)
- 💡 **Discussions**: [GitHub Discussions](https://github.com/drengskapur/ghostwire/discussions)

---

**Made with ❤️ for the Kubernetes community**
