#!/bin/bash

echo "Starting RÚV Web UI..."
echo "Running as user: $(whoami) (UID: $(id -u), GID: $(id -g))"

# Create necessary directories with correct permissions first
mkdir -p /app/data/.ruvsarpur /home/appuser/.ruvsarpur /app/backend/downloads
chmod -R 777 /app/backend/downloads
chown -R appuser:appuser /app/data/.ruvsarpur /home/appuser/.ruvsarpur

# Function to refresh EPG data
refresh_epg() {
    echo "Refreshing EPG data..."
    cd /app/ruvsarpur
    su - appuser -c "cd /app/ruvsarpur && python3 ruvsarpur.py --refresh --list"
    if [ $? -eq 0 ]; then
        cp /home/appuser/.ruvsarpur/tvschedule.json /app/data/.ruvsarpur/
        chown appuser:appuser /app/data/.ruvsarpur/tvschedule.json
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

# Switch to appuser and start both services
su - appuser << 'EOF'
# Start FastAPI backend
cd /app/backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8001 &

# Wait a moment for backend to start
sleep 2

# Start Flask frontend
cd /app
exec python app.py
EOF 