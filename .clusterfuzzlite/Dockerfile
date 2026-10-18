# ClusterFuzzLite build image. Scorecard detects fuzzing from this file.
# https://google.github.io/clusterfuzzlite/build-integration/go-lang/
# No USER instruction: the OSS-Fuzz builder compiles as root and writes to /out.
# DS-0002 is ignored for that reason in .trivyignore.
FROM gcr.io/oss-fuzz-base/base-builder-go@sha256:1dbadefbb28c6bfd796c64d9c2115977deb8f19494533cc5a3b724c3441df23d

# Helm renders the chart under test. The archive is pinned by sha256.
ARG HELM_VERSION=v3.22.0
ARG HELM_SHA256=1e4ab49e429626cf6c6958d914248b78c9730803c2751b87627e171dc800e7bb
RUN curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" -o /tmp/helm.tar.gz \
    && echo "${HELM_SHA256}  /tmp/helm.tar.gz" | sha256sum -c \
    && tar -xzf /tmp/helm.tar.gz -C /tmp \
    && mv /tmp/linux-amd64/helm /usr/local/bin/helm \
    && rm -rf /tmp/helm.tar.gz /tmp/linux-amd64 \
    && helm version

COPY . $SRC/ghostwire
WORKDIR $SRC/ghostwire
COPY .clusterfuzzlite/build.sh $SRC/build.sh
