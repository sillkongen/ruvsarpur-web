#!/bin/bash

# Get the absolute path of the script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Current directory: $(pwd)"
echo "Script directory: ${SCRIPT_DIR}"

# Create necessary directories with proper permissions
echo "Creating directories..."
mkdir -p "${SCRIPT_DIR}/data/epg"
mkdir -p "${SCRIPT_DIR}/downloads"
mkdir -p "${SCRIPT_DIR}/data/.ruvsarpur"

# Verify directories exist
echo "Verifying directories..."
if [ ! -d "${SCRIPT_DIR}/data/epg" ]; then
    echo "ERROR: Failed to create ${SCRIPT_DIR}/data/epg"
    exit 1
fi
if [ ! -d "${SCRIPT_DIR}/downloads" ]; then
    echo "ERROR: Failed to create ${SCRIPT_DIR}/downloads"
    exit 1
fi
if [ ! -d "${SCRIPT_DIR}/data/.ruvsarpur" ]; then
    echo "ERROR: Failed to create ${SCRIPT_DIR}/data/.ruvsarpur"
    exit 1
fi

# Set permissions
echo "Setting permissions..."
chmod -R 777 "${SCRIPT_DIR}/data/epg"
chmod -R 777 "${SCRIPT_DIR}/downloads"
chmod -R 777 "${SCRIPT_DIR}/data"

# If running as root, ensure directories are owned by the correct user
if [ "$(id -u)" = "0" ]; then
    echo "Running as root, setting ownership..."
    chown -R 501:501 "${SCRIPT_DIR}/data/epg"
    chown -R 501:501 "${SCRIPT_DIR}/downloads"
    chown -R 501:501 "${SCRIPT_DIR}/data"
else
    # If not running as root, try to use sudo
    if command -v sudo >/dev/null 2>&1; then
        echo "Using sudo to set ownership..."
        sudo chown -R 501:501 "${SCRIPT_DIR}/data/epg"
        sudo chown -R 501:501 "${SCRIPT_DIR}/downloads"
        sudo chown -R 501:501 "${SCRIPT_DIR}/data"
    fi
fi

echo "Directory permissions set up complete"
echo "Directory structure:"
tree "${SCRIPT_DIR}/data" "${SCRIPT_DIR}/downloads"
echo "Directory permissions:"
ls -la "${SCRIPT_DIR}/data/epg"
ls -la "${SCRIPT_DIR}/downloads"
ls -la "${SCRIPT_DIR}/data" 