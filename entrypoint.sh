#!/bin/bash

echo "Starting RÚV Web UI..."
echo "Running as user: $(whoami) (UID: $(id -u), GID: $(id -g))"

# Get host user and group IDs from environment variables
HOST_UID=${HOST_UID:-1000}
HOST_GID=${HOST_GID:-1000}
echo "Host UID: $HOST_UID, Host GID: $HOST_GID"

# Create necessary directories with proper permissions
echo "Creating necessary directories..."
mkdir -p /home/appuser/.ruvsarpur
mkdir -p /app/data/.ruvsarpur
mkdir -p /app/backend/downloads
mkdir -p /app/downloads

# Set permissions for all directories (world writable so any user can access)
chmod -R 777 /home/appuser/.ruvsarpur
chmod -R 777 /app/data/.ruvsarpur
chmod -R 777 /app/backend/downloads
chmod -R 777 /app/downloads

# Debug: Check permissions of mounted volumes
echo "Checking mounted volume permissions:"
echo "=== /home/appuser/.ruvsarpur ==="
ls -la /home/appuser/.ruvsarpur
echo "=== /app/data/.ruvsarpur ==="
ls -la /app/data/.ruvsarpur
echo "=== /app/data ==="
ls -la /app/data
echo "=== /app/downloads ==="
ls -la /app/downloads

# Function to refresh EPG data
refresh_epg() {
    echo "Refreshing EPG data..."
    cd /app/ruvsarpur
    python3 ruvsarpur.py --refresh --list
    if [ $? -eq 0 ]; then
        # Copy the schedule file to the fallback location
        cp /home/appuser/.ruvsarpur/tvschedule.json /app/data/.ruvsarpur/ 2>/dev/null || true
        
        # Set ownership of created files to match host user
        if [ -f /home/appuser/.ruvsarpur/tvschedule.json ]; then
            chown $HOST_UID:$HOST_GID /home/appuser/.ruvsarpur/tvschedule.json 2>/dev/null || true
        fi
        if [ -f /app/data/.ruvsarpur/tvschedule.json ]; then
            chown $HOST_UID:$HOST_GID /app/data/.ruvsarpur/tvschedule.json 2>/dev/null || true
        fi
        
        echo "✅ EPG data refreshed successfully!"
    else
        echo "❌ Failed to refresh EPG data"
        exit 1
    fi
}

# Check if EPG data exists and its age
if [ -f /home/appuser/.ruvsarpur/tvschedule.json ]; then
    # Get file age in seconds and convert to hours/minutes
    file_age_seconds=$(( $(date +%s) - $(stat -c %Y /home/appuser/.ruvsarpur/tvschedule.json) ))
    file_age_hours=$(( file_age_seconds / 3600 ))
    file_age_minutes=$(( file_age_seconds / 60 ))
    echo "EPG data is ${file_age_hours} hours old (${file_age_minutes} minutes)"
    
    # Refresh if older than 5 minutes (for testing - change to 2 hours for production)
    if [ $file_age_minutes -gt 5 ]; then
        echo "EPG data is more than 5 minutes old (${file_age_minutes} min), refreshing..."
        refresh_epg
    else
        echo "EPG data is recent enough, proceeding with startup..."
    fi
else
    echo "No EPG data found. Downloading initial EPG data..."
    refresh_epg
fi

# Set PYTHONPATH
export PYTHONPATH=/app:/app/ruvsarpur:/app/backend

# Start both services
echo "Starting FastAPI backend..."
cd /app
python3 -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8001 &
BACKEND_PID=$!

# Wait a moment for backend to start
sleep 3

echo "Starting Flask frontend..."
cd /app
python3 app.py &
FRONTEND_PID=$!

# Wait for either process to exit
wait $BACKEND_PID $FRONTEND_PID 