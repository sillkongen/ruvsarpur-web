#!/bin/bash

# Create necessary directories with proper permissions
mkdir -p "${HOME}/.ruvsarpur"
mkdir -p "./downloads"
mkdir -p "./data/.ruvsarpur"

# Set permissions
chmod -R 755 "${HOME}/.ruvsarpur"
chmod -R 777 "./downloads"
chmod -R 755 "./data"

# If running as root, ensure directories are owned by the correct user
if [ "$(id -u)" = "0" ]; then
    chown -R 501:501 "${HOME}/.ruvsarpur"
    chown -R 501:501 "./downloads"
    chown -R 501:501 "./data"
fi

echo "Directory permissions set up complete" 