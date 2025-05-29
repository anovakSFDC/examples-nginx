#!/bin/bash

SOCKET_PATH="/tmp/nginx.socket"
APP_INITIALIZED_FILE="/tmp/app-initialized"

echo "Starting mock app server..."

# Clean up existing socket
rm -f "$SOCKET_PATH"

# Create a simple HTTP server using socat (if available) or netcat
if command -v socat >/dev/null 2>&1; then
    echo "Using socat to create HTTP server"

    # Create app-initialized file to signal readiness
    touch "$APP_INITIALIZED_FILE"
    echo "Created $APP_INITIALIZED_FILE - app is ready for nginx"

    # Start HTTP server on Unix socket
    while true; do
        echo -e "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 88\r\n\r\n{\"message\":\"Hello from mock app behind nginx!\",\"timestamp\":\"$(date -Iseconds)\"}" | socat UNIX-LISTEN:"$SOCKET_PATH",fork -
    done
else
    echo "socat not available, creating a simple mock server"

    # Create app-initialized file to signal readiness
    touch "$APP_INITIALIZED_FILE"
    echo "Created $APP_INITIALIZED_FILE - app is ready for nginx"

    # Simple infinite loop to keep the process running
    # In real usage, this would be your actual app server
    while true; do
        sleep 1
    done
fi