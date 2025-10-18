# syntax=docker/dockerfile:1

# hadolint ignore=DL3007
FROM cgr.dev/chainguard/wolfi-base:latest

LABEL org.opencontainers.image.title="Ghostwire Signal Desktop" \
      org.opencontainers.image.description="Signal Desktop with VNC access on Chainguard Wolfi" \
      org.opencontainers.image.vendor="Drengskapur" \
      org.opencontainers.image.source="https://github.com/drengskapur/ghostwire" \
      org.opencontainers.image.licenses="Apache-2.0"

USER root

# Install VNC and X11 dependencies from Wolfi
# Signal Desktop .deb already includes all GTK/GUI libraries
# hadolint ignore=DL3018
RUN apk update && apk add --no-cache \
    # Core system
    bash \
    busybox \
    ca-certificates-bundle \
    curl \
    wget \
    procps \
    shadow \
    coreutils \
    binutils \
    zstd \
    libunwind \
    # X11 utilities
    xkeyboard-config \
    xkbcomp \
    xdpyinfo \
    libxfont \
    # Lightweight window manager
    openbox \
    # Fonts
    fontconfig \
    ttf-dejavu \
    font-liberation \
    # Process supervisor
    supervisor \
    # Audio subsystem
    dbus \
    dbus-x11 \
    pulseaudio \
    alsa-lib \
    pulseaudio-utils \
    # GTK3 and rendering libraries
    gtk-3 \
    gdk-pixbuf \
    at-spi2-core \
    cairo \
    pango \
    glib \
    # X11 client libraries and extensions
    libx11 \
    libxext \
    libxfixes \
    libxrender \
    libxi \
    libxtst \
    libxcursor \
    libxinerama \
    libxss \
    libxcomposite \
    libxdamage \
    libxrandr \
    libxshmfence \
    libxkbcommon \
    # OpenGL/Mesa for software rendering
    mesa \
    mesa-gl \
    mesa-egl \
    mesa-gbm \
    libdrm \
    vulkan-loader \
    # Electron/Chromium dependencies
    libnss \
    libnotify \
    cups-libs \
    expat \
    # System essentials
    glibc-locale-posix \
    libseccomp \
    tzdata \
    shared-mime-info \
    hicolor-icon-theme \
    # Utilities
    xterm \
    netcat-openbsd \
    && rm -rf /var/cache/apk/*

# Set bash with pipefail for remaining commands
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install KasmVNC from official .deb package
# KasmVNC has native WebSocket support and includes its own web interface
ARG KASMVNC_VERSION=1.4.0
ARG KASMVNC_COMMIT=663b6d6a0bdd4638bff981c75a522056aaaa1c2e
RUN curl -fsSL "https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/${KASMVNC_COMMIT}/kasmvncserver_jammy_${KASMVNC_VERSION}_amd64.deb" \
    -o kasmvnc.deb && \
    ar x kasmvnc.deb && \
    zstd -d data.tar.zst && \
    tar -xf data.tar -C / && \
    rm -f kasmvnc.deb data.tar data.tar.zst control.tar.* debian-binary

# Install Signal Desktop from official .deb package
# Extract .deb since we're on Wolfi (not Debian/Ubuntu)
# Signal .deb includes all GTK and application dependencies
ARG SIGNAL_VERSION=7.0.0
WORKDIR /tmp
RUN curl -fsSL "https://updates.signal.org/desktop/apt/pool/s/signal-desktop/signal-desktop_${SIGNAL_VERSION}_amd64.deb" \
    -o signal.deb && \
    ar x signal.deb && \
    tar -xf data.tar.xz -C / && \
    rm -f signal.deb data.tar.xz control.tar.* debian-binary

# Create non-root user with proper home directory
RUN groupadd -g 1000 ghostwire && \
    useradd -m -u 1000 -g 1000 -s /bin/bash ghostwire && \
    mkdir -p \
        /home/ghostwire/.config/openbox \
        /home/ghostwire/.config/Signal \
        /home/ghostwire/.config/pulse \
        /home/ghostwire/Desktop \
        /var/log/supervisor \
        /var/lib/dbus \
        /tmp/.X11-unix \
        /etc/supervisor/conf.d \
        /etc/kasmvnc && \
    chown -R ghostwire:ghostwire /home/ghostwire && \
    chown ghostwire:ghostwire /var/log/supervisor && \
    dbus-uuidgen > /var/lib/dbus/machine-id && \
    chmod 1777 /tmp/.X11-unix

# Copy configuration and scripts
COPY --chown=root:root config/supervisord.conf /etc/supervisor/supervisord.conf
COPY --chown=root:root config/kasmvnc.yaml /etc/kasmvnc/kasmvnc.yaml
COPY --chown=ghostwire:ghostwire config/openbox-rc.xml /home/ghostwire/.config/openbox/rc.xml
COPY --chown=ghostwire:ghostwire config/openbox-menu.xml /home/ghostwire/.config/openbox/menu.xml
COPY --chown=root:root --chmod=755 scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chown=root:root --chmod=755 scripts/signal-wrapper.sh /usr/local/bin/signal-wrapper.sh
COPY --chown=root:root --chmod=755 scripts/healthcheck.sh /usr/local/bin/healthcheck.sh

# Environment variables
ENV DISPLAY=":1" \
    VNC_PORT="5901" \
    NOVNC_PORT="6901" \
    VNC_RESOLUTION="1280x720" \
    VNC_COL_DEPTH="24" \
    HOME="/home/ghostwire"

# Expose ports
EXPOSE 5901 6901

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

WORKDIR /home/ghostwire

# Run as root to allow KasmVNC to create X11 sockets
# Individual services will run as ghostwire user via supervisord config
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
