#!/bin/sh

usage() {
    echo "\
Usage: $0 -p <PUB_KEY> [OPTION]...

The script automates the process of adding an SSH public key to your user's authorized_keys file and applies the correct strict permissions required by SSH.

Parameters:
    -p, --pub, --pub-key
        The SSH Public Key (e.g., \$(cat \".pub\"))

Options:
    -h, --help
        Print help
"
    exit 1
}

# Configure parameters
if [ "$#" -eq 0 ]; then
    usage
fi

PUB_KEY=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        -p|--pub|--pub-key)
            shift
            PUB_KEY="$1"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate that inputs are not empty
if [ -z "$PUB_KEY" ]; then
    echo "Error: The SSH Public Key are required."
    echo ""
    usage
fi

# Determine the actual user (even if running via sudo)
REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
SSH_DIR="$USER_HOME/.ssh"
AUTH_KEYS="$SSH_DIR/authorized_keys"

# Create the .ssh directory if it doesn't exist
mkdir -p "$SSH_DIR"

# --- Write authorized_keys file ---
echo "$PUB_KEY" >> "$AUTH_KEYS"
echo "Public key successfully added."

# Set correct permissions (Critical for SSH Key login)
chmod 700 "$SSH_DIR"
chmod 600 "$AUTH_KEYS"
chown -R "$REAL_USER:$REAL_USER" "$SSH_DIR"
echo "Public key successfully added for user: $REAL_USER"

echo "Restart the sshd service to make it work properly."
