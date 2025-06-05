#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Script directory: $SCRIPT_DIR"

# Detect current user ID and group ID
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)
echo "Current user UID: $CURRENT_UID, GID: $CURRENT_GID"

# Export these as environment variables for docker-compose
export HOST_UID=$CURRENT_UID
export HOST_GID=$CURRENT_GID
echo "Setting HOST_UID=$HOST_UID and HOST_GID=$HOST_GID"

# Create necessary directories with proper permissions
echo "Creating and setting permissions for data directories..."

# Create directories if they don't exist
mkdir -p "$SCRIPT_DIR/data/epg"
mkdir -p "$SCRIPT_DIR/downloads"
mkdir -p "$SCRIPT_DIR/data/.ruvsarpur"

# Set permissions for all directories (world writable)
echo "Setting permissions for data directories..."
chmod -R 777 "$SCRIPT_DIR/data"
chmod -R 777 "$SCRIPT_DIR/downloads"

# If running as root, change ownership to match the detected user
if [ "$EUID" -eq 0 ]; then
    echo "Running as root, setting ownership to UID $CURRENT_UID..."
    chown -R $CURRENT_UID:$CURRENT_GID "$SCRIPT_DIR/data"
    chown -R $CURRENT_UID:$CURRENT_GID "$SCRIPT_DIR/downloads"
else
    echo "Not running as root, ownership will be inherited from parent directory"
fi

# Verify the directories exist and have correct permissions
echo "Verifying directory permissions:"
ls -la "$SCRIPT_DIR/data"
ls -la "$SCRIPT_DIR/downloads"

echo "Pre-start script completed successfully"
echo "Environment variables set:"
echo "  HOST_UID=$HOST_UID"
echo "  HOST_GID=$HOST_GID"
echo ""
echo "Now you can run: docker-compose up --build" 