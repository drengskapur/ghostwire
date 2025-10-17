# syntax=docker/dockerfile:1
FROM cgr.dev/chainguard/wolfi-base:latest

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
      org.opencontainers.image.base.name="cgr.dev/chainguard/wolfi-base:latest"

RUN apk update && apk add \
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
    python-3.12

WORKDIR /workspace
ENTRYPOINT ["/bin/bash", "-l"]
