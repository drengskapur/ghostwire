# K8s/Network Debug Image - Lean Version
FROM cgr.dev/chainguard/wolfi-base:latest

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