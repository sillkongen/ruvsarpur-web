#!/bin/bash

echo "Starting RÚV Web UI..."
echo "Running as user: $(whoami) (UID: $(id -u), GID: $(id -g))"

# Create necessary directories with correct permissions first
mkdir -p /app/data/.ruvsarpur /home/appuser/.ruvsarpur /app/backend/downloads
chmod -R 777 /app/backend/downloads
chown -R appuser:appuser /app/data/.ruvsarpur /home/appuser/.ruvsarpur

# Run ruvsarpur as appuser
if [ ! -f /home/appuser/.ruvsarpur/tvschedule.json ]; then
    echo "No EPG data found. Downloading initial EPG data..."
    echo "This may take 15-20 seconds..."
    
    # Use ruvsarpur to fetch latest EPG data
    cd /app/ruvsarpur
    # Run as appuser with --list to prevent downloading shows
    su - appuser -c "cd /app/ruvsarpur && python3 ruvsarpur.py --refresh --list"
    
    # Check if download was successful
    if [ -f /home/appuser/.ruvsarpur/tvschedule.json ]; then
        # Copy to data directory for persistence (as root)
        cp /home/appuser/.ruvsarpur/tvschedule.json /app/data/.ruvsarpur/
        chown appuser:appuser /app/data/.ruvsarpur/tvschedule.json
        echo "✅ EPG data downloaded successfully!"
    else
        echo "❌ Failed to download EPG data"
        exit 1
    fi
else
    echo "EPG data found, proceeding with startup..."
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