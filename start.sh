#!/bin/bash

# RÚV Web Downloader Startup Script
# This script sets the correct user/group IDs to avoid permission issues

echo "🚀 Starting RÚV Web Downloader..."

# Get current user's UID and GID
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)

echo "👤 Using UID: $USER_ID, GID: $GROUP_ID"

# Create directories if they don't exist
mkdir -p downloads data

# Run setup if EPG data is available
if [ -f "$HOME/.ruvsarpur/tvschedule.json" ]; then
    echo "📺 Setting up EPG data..."
    ./setup-epg.sh
else
    echo "⚠️  No EPG data found. You may need to run ruvsarpur first to generate EPG data."
    echo "   The application will still work but search may be limited."
fi

# Start Docker Compose with user ID arguments
echo "🐳 Starting containers..."
docker-compose up --build

echo "✅ RÚV Web Downloader stopped." 