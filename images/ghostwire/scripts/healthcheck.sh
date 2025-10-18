#!/bin/bash
set -e

# Check if X11 is responding
if ! xdpyinfo -display "${DISPLAY}" >/dev/null 2>&1; then
    echo "UNHEALTHY: X11 not responding"
    exit 1
fi

# Check if x11vnc is listening
if ! nc -z localhost "${VNC_PORT}" 2>/dev/null; then
    echo "UNHEALTHY: VNC server not listening on port ${VNC_PORT}"
    exit 1
fi

# Check if noVNC is listening
if ! nc -z localhost "${NOVNC_PORT}" 2>/dev/null; then
    echo "UNHEALTHY: noVNC not listening on port ${NOVNC_PORT}"
    exit 1
fi

# Check if Signal Desktop process is running
if ! pgrep -x "signal-desktop" > /dev/null; then
    echo "UNHEALTHY: Signal Desktop not running"
    exit 1
fi

echo "HEALTHY: All services running"
exit 0
