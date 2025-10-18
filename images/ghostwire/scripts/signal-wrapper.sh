#!/bin/bash
set -e

echo "[Signal] Waiting for X11 display ${DISPLAY} to be ready..."

# Wait for X11 server with timeout
TIMEOUT=60
COUNTER=0

while ! xdpyinfo -display "${DISPLAY}" >/dev/null 2>&1; do
    sleep 1
    COUNTER=$((COUNTER + 1))

    if [ $COUNTER -ge $TIMEOUT ]; then
        echo "[Signal] ERROR: X11 server failed to start within ${TIMEOUT} seconds"
        exit 1
    fi

    if [ $((COUNTER % 10)) -eq 0 ]; then
        echo "[Signal] Still waiting for X11... (${COUNTER}/${TIMEOUT}s)"
    fi
done

echo "[Signal] X11 is ready!"
echo "[Signal] Starting Signal Desktop..."

# Start Signal Desktop with container-appropriate flags
exec /opt/Signal/signal-desktop \
    --no-sandbox \
    --disable-dev-shm-usage \
    --use-gl=swiftshader \
    2>&1 | while IFS= read -r line; do echo "[Signal] $line"; done
