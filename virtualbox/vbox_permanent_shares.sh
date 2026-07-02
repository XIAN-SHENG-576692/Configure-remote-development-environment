#!/bin/sh

usage() {
    echo "\
Usage: $0 -m <MOUNT_POINT> -s <SHARE_NAME> [OPTION]...

Configures automounting for shared folders on boot.

This script must be run as root (e.g., using sudo).

Parameters:
  -m, --mount
      The desired Mount Point Path (e.g., /mnt/outside)

  -s, --share
      The VirtualBox Shared Folder Name (e.g., shared)

Options:
  -h, --help
      Print help
"
    exit 1
}

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root (e.g., using sudo)."
    echo ""
    usage
fi

# Configure parameters
if [ "$#" -eq 0 ]; then
    usage
fi

MOUNT_POINT=""
SHARE_NAME=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        -m|--mount)
            shift
            MOUNT_POINT="$1"
            shift
            ;;
        -s|--share)
            shift
            SHARE_NAME="$1"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate that inputs are not empty
if [ -z "$MOUNT_POINT" ] || [ -z "$SHARE_NAME" ]; then
    echo "Error: Both the shared folder name and the mount path are required."
    echo ""
    usage
fi

# Create the mount point directory
mkdir -p "$MOUNT_POINT"

# Ensure the kernel module configuration directory exists
mkdir -p /etc/modules-load.d
echo "vboxsf" > /etc/modules-load.d/vboxsf.conf

# Attempt to load the module immediately
modprobe vboxsf 2>/dev/null || echo "Note: vboxsf module not loaded yet; it will load after reboot."

# --- Detect Init System and Configure Persistence ---

if [ -d /run/systemd/system ]; then
    # [Systemd / glibc System] (e.g., Ubuntu, Debian, Fedora)
    echo "Detected systemd (Commonly glibc)..."
    
    # Adding to /etc/fstab is the most reliable method for systemd
    # 'nofail' prevents the system from hanging if the share is missing
    FSTAB_ENTRY="$SHARE_NAME $MOUNT_POINT vboxsf defaults,nofail 0 0"
    
    if ! grep -q "$SHARE_NAME $MOUNT_POINT" /etc/fstab; then
        echo "$FSTAB_ENTRY" >> /etc/fstab
        echo "Added entry to /etc/fstab."
    fi
    mount -a

elif [ -x /sbin/openrc-run ] || [ -d /etc/local.d ]; then
    # [OpenRC / musl System] (e.g., Alpine Linux)
    echo "Detected OpenRC (Commonly musl)..."
    
    rc-update add local default >/dev/null 2>&1
    echo "mount -t vboxsf $SHARE_NAME $MOUNT_POINT" > /etc/local.d/vbox_mount.start
    chmod +x /etc/local.d/vbox_mount.start
    
    # Execute immediately
    sh /etc/local.d/vbox_mount.start
    echo "Configured via /etc/local.d/vbox_mount.start."

else
    # [Fallback for other simple Init systems]
    echo "Unknown init system. Attempting fallback to /etc/rc.local..."
    echo "mount -t vboxsf $SHARE_NAME $MOUNT_POINT" >> /etc/rc.local
    chmod +x /etc/rc.local 2>/dev/null
fi

echo "-------------------------------------------------------"
echo "Success! The shared folder '$SHARE_NAME' is configured to mount at '$MOUNT_POINT' on boot."
