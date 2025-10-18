#!/usr/bin/env bash
# Ghostwire Signal Entrypoint
# Sets up the environment and launches supervisor

set -e

echo "🚀 Starting Ghostwire Signal Desktop..."

# Create runtime directories
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Ensure kasm-user owns their home directory
chown -R kasm-user:kasm-user /home/kasm-user

# Set up VNC password if provided
if [ -n "${VNC_PASSWORD}" ]; then
    mkdir -p /home/kasm-user/.vnc
    echo "${VNC_PASSWORD}" | vncpasswd -f > /home/kasm-user/.vnc/passwd
    chmod 600 /home/kasm-user/.vnc/passwd
    chown kasm-user:kasm-user /home/kasm-user/.vnc/passwd
fi

# Execute the command
exec "$@"
