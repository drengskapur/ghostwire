ARG VARIANT=2.0-bookworm
FROM mcr.microsoft.com/devcontainers/go:${VARIANT}

# Install Node.js (needed for Playwright) with pinned version
ARG NODE_VERSION=22.12.0
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install kubectl with pinned version
ARG KUBECTL_VERSION=v1.31.3
RUN curl -sSL https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

# Install Helm with pinned version
ARG HELM_VERSION=v3.16.3
RUN curl -sSL https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -o /tmp/helm.tar.gz \
    && tar -zxf /tmp/helm.tar.gz -C /tmp \
    && mv /tmp/linux-amd64/helm /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    && rm -rf /tmp/helm.tar.gz /tmp/linux-amd64

# Install k3d with pinned release
ARG K3D_VERSION=v5.7.4
RUN curl -sSL https://github.com/k3d-io/k3d/releases/download/${K3D_VERSION}/k3d-linux-amd64 -o /usr/local/bin/k3d \
    && chmod +x /usr/local/bin/k3d

# Install additional tools with pinned versions
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    jq=1.6-2.1+deb12u1 \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/* \
    && curl -sSL https://github.com/mikefarah/yq/releases/download/v4.40.5/yq_linux_amd64 -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# Install Playwright with pinned version and browsers
ARG PLAYWRIGHT_VERSION=1.49.1
RUN npm install -g playwright@${PLAYWRIGHT_VERSION} \
    && npx playwright@${PLAYWRIGHT_VERSION} install --with-deps chromium

# Pre-pull commonly used images (best effort, don't fail build)
RUN docker pull rancher/k3s:v1.28.5-k3s1 2>/dev/null || true \
    && docker pull kasmweb/signal:1.18.0-rolling-daily 2>/dev/null || true \
    && docker pull mcr.microsoft.com/playwright:v${PLAYWRIGHT_VERSION}-jammy 2>/dev/null || true

# Cache Helm plugins with pinned version
RUN helm plugin install https://github.com/helm-unittest/helm-unittest --version v0.6.2 || true

USER vscode
