#!/bin/sh

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root (e.g., using sudo)."
    exit 1
fi

SCRIPT_DIR=$(cd $(dirname $0); pwd)

SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP_FILE="/etc/ssh/sshd_config.bak_$(date +%F_%T)"

echo "--- Step 1: Backing up configuration ---"
cp "$SSHD_CONFIG" "$BACKUP_FILE"
echo "Backup created at $BACKUP_FILE"

echo "--- Step 2: Updating SSH settings ---"
# Apply configurations using sed
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' "$SSHD_CONFIG"
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONFIG"
sed -i 's/^#\?AllowTcpForwarding.*/AllowTcpForwarding yes/' "$SSHD_CONFIG"
sed -i 's/^#\?PermitEmptyPasswords.*/PermitEmptyPasswords no/' "$SSHD_CONFIG"

echo "--- Step 3: Restarting SSH ---"
if [[ $SCRIPT_DIR/restart_sshd.sh -ne 0 ]]; then
   echo "Restoring backup..."
   cp "$BACKUP_FILE" "$SSHD_CONFIG"
   exit 1
fi
