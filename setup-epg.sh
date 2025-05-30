#!/bin/bash

# Setup script for RÚV Web EPG data
# ⚠️  COPYRIGHT NOTICE: EPG data is copyrighted by RÚV and should NEVER be committed to version control

echo "Setting up EPG data for RÚV Web..."
echo "⚠️  Note: EPG data is copyrighted by RÚV and excluded from version control"

# Create data directory if it doesn't exist
mkdir -p data/.ruvsarpur

# Check if user has EPG data
if [ -f "$HOME/.ruvsarpur/tvschedule.json" ]; then
    echo "Found EPG data at $HOME/.ruvsarpur/tvschedule.json"
    echo "Copying to local data directory..."
    cp "$HOME/.ruvsarpur/tvschedule.json" "data/.ruvsarpur/"
    echo "EPG data copied successfully!"
    echo "⚠️  This data is excluded from Git and will NOT be committed"
else
    echo "ERROR: No EPG data found at $HOME/.ruvsarpur/tvschedule.json"
    echo "Please run ruvsarpur at least once to generate the EPG data:"
    echo "  cd ../ruv-container/ruvsarpur/src"
    echo "  python ruvsarpur.py --help"
    exit 1
fi

echo "Setup complete! You can now run: docker-compose up" 