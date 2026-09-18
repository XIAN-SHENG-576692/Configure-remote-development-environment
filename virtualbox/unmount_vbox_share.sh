#!/bin/sh

usage() {
    echo "\
Usage: $0 -m <MOUNT_POINT> -s <SHARE_NAME> [OPTION]...

Unmounts the VirtualBox shared folder and removes persistent boot configuration.

This script must be run as root (e.g., using sudo).

Parameters:
    -m, --mount
        The Mount Point Path to unmount (e.g., /mnt/outside)

    -s, --share
        The VirtualBox Shared Folder Name (e.g., shared)

Options:
    -r, --remove-dir
        Remove the mount point directory if empty after unmounting

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
REMOVE_DIR=false

while [ $# -gt 0 ]; do
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
        -r|--remove-dir)
            REMOVE_DIR=true
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

echo "Unmounting '$MOUNT_POINT'..."

# 1. Unmount the path
if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
    umount -l "$MOUNT_POINT"
    if [ $? -eq 0 ]; then
        echo "Successfully unmounted '$MOUNT_POINT'."
    else
        echo "Warning: Failed to unmount '$MOUNT_POINT'. Moving on to clean configuration..."
    fi
else
    echo "Notice: '$MOUNT_POINT' is not currently mounted."
fi

# 2. Clean persistent mount configurations based on Init System

if [ -d /run/systemd/system ]; then
    # [Systemd System] Remove entry from /etc/fstab
    echo "Detected systemd. Cleaning /etc/fstab..."
    if [ -f /etc/fstab ]; then
        # Escape special characters for sed regex pattern matching
        ESC_MOUNT=$(echo "$MOUNT_POINT" | sed 's/[[\.*^$]/\\&/g')
        ESC_SHARE=$(echo "$SHARE_NAME" | sed 's/[[\.*^$]/\\&/g')
        
        # Remove line matching the share and mount point
        sed -i "\#${ESC_SHARE}.*${ESC_MOUNT}.*vboxsf#d" /etc/fstab
        echo "Removed persistent entry from /etc/fstab."
    fi

elif [ -x /sbin/openrc-run ] || [ -d /etc/local.d ]; then
    # [OpenRC System] Remove OpenRC start script
    echo "Detected OpenRC. Removing /etc/local.d/vbox_mount.start..."
    if [ -f /etc/local.d/vbox_mount.start ]; then
        rm -f /etc/local.d/vbox_mount.start
        echo "Removed /etc/local.d/vbox_mount.start."
    fi

else
    # [Fallback System] Clean /etc/rc.local
    echo "Unknown init system. Cleaning /etc/rc.local..."
    if [ -f /etc/rc.local ]; then
        ESC_MOUNT=$(echo "$MOUNT_POINT" | sed 's/[[\.*^$]/\\&/g')
        ESC_SHARE=$(echo "$SHARE_NAME" | sed 's/[[\.*^$]/\\&/g')
        sed -i "\#mount -t vboxsf ${ESC_SHARE} ${ESC_MOUNT}#d" /etc/rc.local
        echo "Removed line from /etc/rc.local."
    fi
fi

# 3. Optional: Remove empty mount directory
if [ "$REMOVE_DIR" = true ]; then
    if [ -d "$MOUNT_POINT" ]; then
        rmdir "$MOUNT_POINT" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "Removed directory '$MOUNT_POINT'."
        else
            echo "Warning: Could not remove directory '$MOUNT_POINT' (it might not be empty)."
        fi
    fi
fi

echo "-------------------------------------------------------"
echo "Success! The shared folder '$SHARE_NAME' has been unmounted and auto-mount setting removed."
