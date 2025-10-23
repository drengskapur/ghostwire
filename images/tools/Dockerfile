# syntax=docker/dockerfile:1
FROM cgr.dev/chainguard/wolfi-base:latest@sha256:be19869fc9a08c4a5798b87b3948daeacd213cfb0bfdc9b43ea3c97c9e07fa0f

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
ENTRYPOINT ["/bin/bash"]
