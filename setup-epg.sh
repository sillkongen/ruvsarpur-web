#!/bin/bash

# Setup script for RÚV Web EPG data

echo "Setting up EPG data for RÚV Web..."

# Create data directory if it doesn't exist
mkdir -p data/.ruvsarpur

# Check if user has EPG data
if [ -f "$HOME/.ruvsarpur/tvschedule.json" ]; then
    echo "Found EPG data at $HOME/.ruvsarpur/tvschedule.json"
    echo "Copying to local data directory..."
    cp "$HOME/.ruvsarpur/tvschedule.json" "data/.ruvsarpur/"
    echo "EPG data copied successfully!"
else
    echo "ERROR: No EPG data found at $HOME/.ruvsarpur/tvschedule.json"
    echo "Please run ruvsarpur at least once to generate the EPG data:"
    echo "  cd ../ruv-container/ruvsarpur/src"
    echo "  python ruvsarpur.py --help"
    exit 1
fi

echo "Setup complete! You can now run: docker-compose up" 