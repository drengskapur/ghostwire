#!/bin/bash
set -e

echo "========================================="
echo "Ghostwire - Signal Desktop with VNC"
echo "========================================="
echo "Display:        ${DISPLAY}"
echo "VNC Port:       ${VNC_PORT}"
echo "noVNC Port:     ${NOVNC_PORT}"
echo "Resolution:     ${VNC_RESOLUTION}x${VNC_COL_DEPTH}"
echo "User:           $(whoami) ($(id -u):$(id -g))"
echo "========================================="

# Clean up any stale X11 sockets
echo "Cleaning up stale X11 sockets..."
rm -rf /tmp/.X11-unix/X* /tmp/.X*-lock || true

# Initialize dbus session
export $(dbus-launch)

# Handle signals gracefully
cleanup() {
    echo "Received shutdown signal, cleaning up..."
    pkill -TERM supervisord || true
    exit 0
}

trap cleanup SIGTERM SIGINT SIGQUIT

# Start supervisor in foreground
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
