ARG VARIANT=1.23-bookworm
FROM mcr.microsoft.com/devcontainers/go:${VARIANT}

# Install Node.js (needed for Playwright)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Install k3d
RUN curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Install additional tools
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    jq \
    yq \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install Playwright and browsers as root (system-wide)
RUN npm install -g playwright@1.40.0 \
    && npx playwright install --with-deps chromium

# Pre-pull commonly used images to speed up development
RUN docker pull rancher/k3s:v1.28.5-k3s1 || true \
    && docker pull kasmweb/signal:1.0.0-rolling-daily || true \
    && docker pull mcr.microsoft.com/playwright:v1.40.0-jammy || true

# Cache Helm plugins
RUN helm plugin install https://github.com/helm-unittest/helm-unittest || true

USER vscode
