#!/bin/bash

echo "Starting RÚV Web UI..."
echo "Running as user: $(whoami) (UID: $(id -u), GID: $(id -g))"

# Create necessary directories with correct permissions first
# Use sudo if available, otherwise try without
if command -v sudo >/dev/null 2>&1; then
    sudo mkdir -p /app/data/.ruvsarpur /home/appuser/.ruvsarpur /app/backend/downloads
    sudo chmod -R 777 /app/backend/downloads
    sudo chown -R $(id -u):$(id -g) /app/data/.ruvsarpur /home/appuser/.ruvsarpur
else
    # Try to create directories without sudo
    mkdir -p /home/appuser/.ruvsarpur /app/backend/downloads
    chmod -R 777 /app/backend/downloads
    # Don't try to change ownership if we don't have permission
fi

# Function to refresh EPG data
refresh_epg() {
    echo "Refreshing EPG data..."
    cd /app/ruvsarpur
    # Run directly as current user
    python3 ruvsarpur.py --refresh --list
    if [ $? -eq 0 ]; then
        # Try to copy with sudo if available
        if command -v sudo >/dev/null 2>&1; then
            sudo cp /home/appuser/.ruvsarpur/tvschedule.json /app/data/.ruvsarpur/
            sudo chown $(id -u):$(id -g) /app/data/.ruvsarpur/tvschedule.json
        else
            # Try without sudo
            cp /home/appuser/.ruvsarpur/tvschedule.json /app/data/.ruvsarpur/ 2>/dev/null || true
        fi
        echo "✅ EPG data refreshed successfully!"
    else
        echo "❌ Failed to refresh EPG data"
        exit 1
    fi
}

# Check if EPG data exists and its age
if [ -f /home/appuser/.ruvsarpur/tvschedule.json ]; then
    # Get file age in hours
    file_age_hours=$(( ($(date +%s) - $(stat -c %Y /home/appuser/.ruvsarpur/tvschedule.json)) / 3600 ))
    echo "EPG data is ${file_age_hours} hours old"
    
    # Refresh if older than 4 hours
    if [ $file_age_hours -gt 4 ]; then
        echo "EPG data is more than 4 hours old, refreshing..."
        refresh_epg
    else
        echo "EPG data is recent enough, proceeding with startup..."
    fi
else
    echo "No EPG data found. Downloading initial EPG data..."
    refresh_epg
fi

# Export PYTHONPATH to include backend directory
export PYTHONPATH=/app:/app/backend:/app/ruvsarpur

# Start both services directly
# Start FastAPI backend
cd /app
echo "Starting FastAPI backend..."
python -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8001 &

# Wait a moment for backend to start
sleep 2

# Start Flask frontend
cd /app
echo "Starting Flask frontend..."
exec python app.py 