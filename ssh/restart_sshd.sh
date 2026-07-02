#!/bin/sh

echo "--- Detecting Init System & Restarting SSH ---"
# Check SSH configuration syntax first
if sshd -t; then
    if command -v systemctl >/dev/null 2>&1; then
        echo "Detected systemd. Restarting service..."
        systemctl restart ssh || systemctl restart sshd
    elif command -v rc-service >/dev/null 2>&1; then
        echo "Detected OpenRC. Restarting service..."
        rc-service sshd restart
    else
        echo "Error: Supported init system (systemd/OpenRC) not found. Please restart SSH manually."
        exit 1
    fi
    echo "SSH service restarted successfully."
else
    echo "Error: SSH configuration syntax is invalid."
    exit 1
fi
