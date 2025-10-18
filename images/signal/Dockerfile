# Ghostwire Signal - Signal Desktop on Wolfi with KasmVNC-compatible architecture
# 
# Build: docker build -t ghostwire/signal:latest images/signal/
# Run:   docker run -p 6901:6901 -v signal-data:/home/kasm-user ghostwire/signal:latest
# Access: http://localhost:6901?keyboard=1

ARG BASE_IMAGE="cgr.dev/chainguard/wolfi-base:latest"
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.title="Ghostwire Signal" \
      org.opencontainers.image.description="Signal Desktop on Wolfi Linux with VNC access" \
      org.opencontainers.image.vendor="Drengskapur" \
      org.opencontainers.image.authors="Drengskapur" \
      org.opencontainers.image.url="https://github.com/drengskapur/ghostwire" \
      org.opencontainers.image.source="https://github.com/drengskapur/ghostwire" \
      org.opencontainers.image.licenses="Apache-2.0" \
      com.kasmweb.image="true"

USER root

# Install core system and X11 dependencies
RUN apk update && apk add --no-cache \
    # Core system
    bash \
    ca-certificates-bundle \
    coreutils \
    curl \
    wget \
    procps \
    htop \
    supervisor \
    openssl \
    # X11 and display server
    xorg-server \
    xvfb \
    xauth \
    xhost \
    xrandr \
    xdpyinfo \
    libx11 \
    libxext \
    libxrender \
    libxrandr \
    libxfixes \
    libxdamage \
    libxcomposite \
    libxi \
    libxtst \
    # VNC server - x11vnc for viewing existing X display
    x11vnc \
    # Window manager - OpenBox for single-app mode
    openbox \
    obconf \
    tint2 \
    # Desktop utilities
    xterm \
    feh \
    xdotool \
    wmctrl \
    xclip \
    xsel \
    pcmanfm \
    # Fonts
    font-dejavu \
    font-liberation \
    font-ubuntu \
    fontconfig \
    # Python for websockify and noVNC
    python-3.13 \
    py3.13-pip \
    py3.13-numpy \
    # Audio (for future KasmVNC integration)
    pulseaudio \
    pulseaudio-utils \
    alsa-lib \
    alsa-utils \
    # Build tools for Signal extraction
    binutils \
    tar \
    gzip \
    # Utilities
    vim \
    nano \
    jq \
    git

# Install websockify for noVNC
RUN pip install --no-cache-dir --break-system-packages websockify

# Download and install noVNC
ARG NOVNC_VERSION="1.5.0"
RUN mkdir -p /usr/share/novnc && \
    wget -qO- "https://github.com/novnc/noVNC/archive/v${NOVNC_VERSION}.tar.gz" | \
    tar xz --strip-components=1 -C /usr/share/novnc && \
    ln -s /usr/share/novnc/vnc.html /usr/share/novnc/index.html

# Download and extract Signal Desktop
ARG SIGNAL_VERSION="7.37.0"
ARG SIGNAL_ARCH="amd64"
RUN wget "https://updates.signal.org/desktop/apt/pool/s/signal-desktop/signal-desktop_${SIGNAL_VERSION}_${SIGNAL_ARCH}.deb" \
         -O /tmp/signal.deb && \
    mkdir -p /tmp/signal && \
    cd /tmp/signal && \
    ar x /tmp/signal.deb && \
    tar -xf data.tar.xz -C / && \
    # Create symlink
    ln -sf /opt/Signal/signal-desktop /usr/bin/signal-desktop && \
    # Cleanup
    rm -rf /tmp/signal /tmp/signal.deb

# Create directory structure (KasmVNC-compatible)
RUN mkdir -p \
    /dockerstartup \
    /dockerstartup/install \
    /var/log/supervisor \
    /home/kasm-user \
    /home/kasm-user/.vnc \
    /home/kasm-user/.config/Signal \
    /home/kasm-user/Desktop \
    /home/kasm-user/Downloads \
    /home/kasm-user/Uploads

# Create kasm-user (UID 1000 for compatibility)
RUN groupadd -g 1000 kasm-user && \
    useradd -m -u 1000 -g 1000 -s /bin/bash kasm-user && \
    chown -R 1000:1000 /home/kasm-user

# Copy startup scripts
COPY scripts/ /dockerstartup/

# Copy configurations
COPY config/ /etc/

# Set permissions on startup scripts
RUN chmod -R 755 /dockerstartup && \
    chmod 644 /dockerstartup/*.log 2>/dev/null || true

# Environment variables (KasmVNC-compatible)
ENV DISPLAY=":1" \
    VNC_PORT="5901" \
    NOVNC_PORT="6901" \
    VNC_COL_DEPTH="24" \
    VNC_RESOLUTION="1280x720" \
    HOME="/home/kasm-user" \
    STARTUPDIR="/dockerstartup" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8"

WORKDIR /home/kasm-user

# Expose noVNC port (compatible with KasmVNC port)
EXPOSE 6901

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:6901/ || exit 1

# Run as root for supervisor (like KasmVNC images)
USER root

ENTRYPOINT ["/dockerstartup/entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
