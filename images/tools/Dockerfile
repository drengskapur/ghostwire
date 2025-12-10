# syntax=docker/dockerfile:1
FROM cgr.dev/chainguard/wolfi-base:latest@sha256:0d8efc73b806c780206b69d62e1b8cb10e9e2eefa0e4452db81b9fa00b1a5175

# OCI Labels and Annotations (OpenContainer Initiative)
# https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL org.opencontainers.image.title="Ghostwire Tools" \
      org.opencontainers.image.description="Comprehensive toolkit for Ghostwire with kubectl, helm, and networking tools" \
      org.opencontainers.image.vendor="Drengskapur" \
      org.opencontainers.image.authors="Drengskapur" \
      org.opencontainers.image.url="https://github.com/drengskapur/ghostwire" \
      org.opencontainers.image.source="https://github.com/drengskapur/ghostwire" \
      org.opencontainers.image.documentation="https://github.com/drengskapur/ghostwire/blob/main/images/tools/README.md" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.base.name="cgr.dev/chainguard/wolfi-base:latest@sha256:9608820b6ea4da8bcf16989dac37a280f8f1fa0022efc45b5ed4b1ac1f634a79"

RUN apk update && apk add --no-cache \
    bash \
    vim \
    jq \
    curl \
    wget \
    iputils \
    bind-tools \
    netcat-openbsd \
    tcpdump \
    nmap \
    kubectl \
    helm \
    docker-cli \
    procps \
    htop \
    openssl \
    git \
    python-3.12 \
    && rm -rf /var/cache/apk/*

# Create non-root user for security
RUN addgroup -g 1000 tooluser \
    && adduser -D -u 1000 -G tooluser tooluser \
    && mkdir -p /workspace \
    && chown -R tooluser:tooluser /workspace

WORKDIR /workspace
USER tooluser
ENTRYPOINT ["/bin/bash"]
