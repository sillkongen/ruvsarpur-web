#!/bin/bash

# RÚV Web Downloader Startup Script
echo "🚀 Starting RÚV Web Downloader..."

# Get current user's UID and GID
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)

echo "👤 Using UID: $USER_ID, GID: $GROUP_ID"

# Create directories if they don't exist and set proper permissions
mkdir -p downloads data
chmod 777 downloads data

# Start Docker Compose with user ID arguments
echo "🐳 Starting containers..."
docker-compose up --build

echo "✅ RÚV Web Downloader stopped." 