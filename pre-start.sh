#!/bin/bash

# Create necessary directories with proper permissions
mkdir -p "./data/epg"
mkdir -p "./downloads"
mkdir -p "./data/.ruvsarpur"

# Set permissions
chmod -R 777 "./data/epg"
chmod -R 777 "./downloads"
chmod -R 777 "./data"

# If running as root, ensure directories are owned by the correct user
if [ "$(id -u)" = "0" ]; then
    chown -R 501:501 "./data/epg"
    chown -R 501:501 "./downloads"
    chown -R 501:501 "./data"
else
    # If not running as root, try to use sudo
    if command -v sudo >/dev/null 2>&1; then
        sudo chown -R 501:501 "./data/epg"
        sudo chown -R 501:501 "./downloads"
        sudo chown -R 501:501 "./data"
    fi
fi

echo "Directory permissions set up complete"
echo "Created directories:"
ls -la ./data/epg
ls -la ./downloads
ls -la ./data 