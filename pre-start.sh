#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Script directory: $SCRIPT_DIR"

# Create necessary directories with proper permissions
echo "Creating and setting permissions for data directories..."

# Create directories if they don't exist
mkdir -p "$SCRIPT_DIR/data/epg"
mkdir -p "$SCRIPT_DIR/downloads"
mkdir -p "$SCRIPT_DIR/data/.ruvsarpur"

# Set permissions for all directories
echo "Setting permissions for data directories..."
chmod -R 777 "$SCRIPT_DIR/data"
chmod -R 777 "$SCRIPT_DIR/downloads"

# If running as root, change ownership to match the container user (UID 501)
if [ "$EUID" -eq 0 ]; then
    echo "Running as root, setting ownership to UID 501..."
    chown -R 501:501 "$SCRIPT_DIR/data"
    chown -R 501:501 "$SCRIPT_DIR/downloads"
else
    echo "Not running as root, ownership will be inherited from parent directory"
fi

# Verify the directories exist and have correct permissions
echo "Verifying directory permissions:"
ls -la "$SCRIPT_DIR/data"
ls -la "$SCRIPT_DIR/downloads"

echo "Pre-start script completed successfully" 