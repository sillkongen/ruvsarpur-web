#!/bin/bash

# Get the absolute path of the script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create necessary directories with proper permissions
mkdir -p "${SCRIPT_DIR}/data/epg"
mkdir -p "${SCRIPT_DIR}/downloads"
mkdir -p "${SCRIPT_DIR}/data/.ruvsarpur"

# Set permissions
chmod -R 777 "${SCRIPT_DIR}/data/epg"
chmod -R 777 "${SCRIPT_DIR}/downloads"
chmod -R 777 "${SCRIPT_DIR}/data"

# If running as root, ensure directories are owned by the correct user
if [ "$(id -u)" = "0" ]; then
    chown -R 501:501 "${SCRIPT_DIR}/data/epg"
    chown -R 501:501 "${SCRIPT_DIR}/downloads"
    chown -R 501:501 "${SCRIPT_DIR}/data"
else
    # If not running as root, try to use sudo
    if command -v sudo >/dev/null 2>&1; then
        sudo chown -R 501:501 "${SCRIPT_DIR}/data/epg"
        sudo chown -R 501:501 "${SCRIPT_DIR}/downloads"
        sudo chown -R 501:501 "${SCRIPT_DIR}/data"
    fi
fi

echo "Directory permissions set up complete"
echo "Created directories:"
ls -la "${SCRIPT_DIR}/data/epg"
ls -la "${SCRIPT_DIR}/downloads"
ls -la "${SCRIPT_DIR}/data" 