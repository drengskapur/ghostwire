#!/usr/bin/env bash
# Signal Desktop Wrapper - Auto-restart with window maximization
# Based on KasmVNC custom_startup.sh pattern

set -e

APP_COMMAND="/usr/bin/signal-desktop"
APP_ARGS="--no-sandbox"
APP_PROCESS="signal-desktop"
MAXIMIZE="${MAXIMIZE:-true}"
MAXIMIZE_NAME="${MAXIMIZE_NAME:-Signal}"
MAX_RESTARTS="${MAX_RESTARTS:-999}"
RESTART_DELAY="${RESTART_DELAY:-2}"

restart_count=0

echo "🔵 Starting Signal Desktop wrapper (max restarts: ${MAX_RESTARTS})"

# Wait for X server to be ready
echo "⏳ Waiting for X server..."
timeout=30
while [ $timeout -gt 0 ]; do
    if xdpyinfo -display "${DISPLAY}" >/dev/null 2>&1; then
        echo "✅ X server is ready"
        break
    fi
    sleep 1
    timeout=$((timeout - 1))
done

if [ $timeout -eq 0 ]; then
    echo "❌ X server failed to start"
    exit 1
fi

# Main restart loop
while [ $restart_count -lt $MAX_RESTARTS ]; do
    echo "🚀 Starting Signal Desktop (attempt $((restart_count + 1)))"
    
    # Start Signal Desktop
    $APP_COMMAND $APP_ARGS &
    signal_pid=$!
    
    # Wait a moment for window to appear
    sleep 3
    
    # Maximize window if requested
    if [ "${MAXIMIZE}" = "true" ]; then
        echo "🔍 Looking for window: ${MAXIMIZE_NAME}"
        for i in {1..10}; do
            if wmctrl -l | grep -q "${MAXIMIZE_NAME}"; then
                echo "📐 Maximizing window"
                wmctrl -r "${MAXIMIZE_NAME}" -b add,maximized_vert,maximized_horz
                break
            fi
            sleep 1
        done
    fi
    
    # Wait for Signal to exit
    wait $signal_pid
    exit_code=$?
    
    echo "⚠️  Signal Desktop exited with code $exit_code"
    
    restart_count=$((restart_count + 1))
    
    if [ $restart_count -lt $MAX_RESTARTS ]; then
        echo "⏱️  Restarting in ${RESTART_DELAY} seconds..."
        sleep $RESTART_DELAY
    fi
done

echo "❌ Max restarts ($MAX_RESTARTS) reached. Exiting."
exit 1
