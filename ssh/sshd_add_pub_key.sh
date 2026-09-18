#!/bin/sh

usage() {
    cat << EOF
Usage: ${0##*/} -p <PUB_KEY> [OPTION]...
    The script automates the process of adding an SSH public key to your user's authorized_keys file and applies the correct strict permissions required by SSH.

Parameters:
    -p, --pub, --pub-key
        The SSH Public Key (e.g., \$(cat \".pub\"))

Options:
    -h, --help
        Print help
EOF
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

# Ensure PUB_KEY is set and non-empty
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
# Strip trailing (and leading) newlines or extra whitespace from the key
PUB_KEY_CLEAN=$(echo "$PUB_KEY" | tr -d '\r\n' | xargs)

# Extract and display key fingerprint (-l reads key, -f - reads from stdin)
PUB_KEY_FINGERPRINT=$(echo "$PUB_KEY_CLEAN" | ssh-keygen -E sha256 -l -f - 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "Error: The provided SSH public key is invalid." >&2
    echo "${PUB_KEY}"
    exit 1
fi

echo "The SSH public key fingerprint: $PUB_KEY_FINGERPRINT"

# Create authorized_keys if it doesn't exist yet
touch "$AUTH_KEYS"

# Check if the public key is already in authorized_keys
if grep -qsF "$PUB_KEY" "$AUTH_KEYS"; then
    echo "The SSH public key is already present in $AUTH_KEYS."
else
    echo "$PUB_KEY" >> "$AUTH_KEYS"
    echo "The SSH public key successfully added to $AUTH_KEYS."
fi

# Set correct permissions (Critical for SSH Key login)
chmod 700 "$SSH_DIR"
chmod 600 "$AUTH_KEYS"
chown -R "$REAL_USER:$REAL_USER" "$SSH_DIR"
echo "The Public key successfully added for user: $REAL_USER"

echo "Restart the sshd service to make it work properly."
