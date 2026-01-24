#!/bin/bash
# uninstall.sh - Remove myscreensavers and its systemd service
# v1.0.0

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVICE_NAME="screensaver-daemon.service"
SERVICE_FILE="$HOME/.config/systemd/user/$SERVICE_NAME"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/myscreensavers"

echo "=== myscreensavers Uninstaller ==="
echo ""

# Confirmation
read -p "This will remove the screensaver daemon service. Continue? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""

# Stop the service if running
if systemctl --user is-active "$SERVICE_NAME" &>/dev/null; then
    echo "Stopping $SERVICE_NAME..."
    systemctl --user stop "$SERVICE_NAME"
fi

# Disable the service
if systemctl --user is-enabled "$SERVICE_NAME" &>/dev/null 2>&1; then
    echo "Disabling $SERVICE_NAME..."
    systemctl --user disable "$SERVICE_NAME"
fi

# Remove service file
if [[ -f "$SERVICE_FILE" ]]; then
    echo "Removing service file: $SERVICE_FILE"
    rm -f "$SERVICE_FILE"
fi

# Reload systemd
echo "Reloading systemd..."
systemctl --user daemon-reload

echo ""
echo "Service removed successfully."
echo ""

# Ask about config directory
if [[ -d "$CONFIG_DIR" ]]; then
    read -p "Remove config directory ($CONFIG_DIR)? [y/N] " rm_config
    if [[ "$rm_config" =~ ^[Yy]$ ]]; then
        rm -rf "$CONFIG_DIR"
        echo "Config directory removed."
    fi
fi

# Ask about project directory
echo ""
read -p "Remove project directory ($SCRIPT_DIR)? [y/N] " rm_project
if [[ "$rm_project" =~ ^[Yy]$ ]]; then
    echo "Removing $SCRIPT_DIR..."
    rm -rf "$SCRIPT_DIR"
    echo "Project directory removed."
else
    echo ""
    echo "Project files remain at: $SCRIPT_DIR"
    echo "You can manually delete with: rm -rf $SCRIPT_DIR"
fi

echo ""
echo "Uninstall complete."
