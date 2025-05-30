FROM python:3.12-slim

# Build arguments for user ID matching
ARG USER_ID=1000
ARG GROUP_ID=1000

# Install system dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user matching host user
RUN groupadd -g ${GROUP_ID} appuser && \
    useradd -u ${USER_ID} -g ${GROUP_ID} -m appuser

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Install ruvsarpur dependencies
RUN pip install --no-cache-dir \
    colorama \
    termcolor \
    requests \
    beautifulsoup4 \
    lxml \
    python-dateutil \
    fuzzywuzzy \
    python-levenshtein

# Copy the application code (including ruvsarpur)
COPY . /app/

# Create necessary directories and set all permissions properly
RUN mkdir -p /app/downloads /app/data && \
    chmod +x /app/ruvsarpur/ruvsarpur.py && \
    chown -R appuser:appuser /app && \
    chmod -R 755 /app

# Create startup script
RUN echo '#!/bin/bash\n\
echo "Starting RÚV Web UI..."\n\
echo "Running as user: $(whoami) (UID: $(id -u), GID: $(id -g))"\n\
echo "Ruvsarpur permissions: $(ls -la /app/ruvsarpur/ruvsarpur.py)"\n\
\n\
# Set HOME for ruvsarpur\n\
export HOME=/home/appuser\n\
\n\
# Create EPG directory with correct ownership\n\
mkdir -p /home/appuser/.ruvsarpur\n\
\n\
# Check for EPG data and download if needed\n\
EPG_LOCATIONS=(\n\
    "/home/appuser/.ruvsarpur/tvschedule.json"\n\
    "/app/data/.ruvsarpur/tvschedule.json"\n\
    "/root/.ruvsarpur/tvschedule.json"\n\
    "/app/.ruvsarpur/tvschedule.json"\n\
)\n\
\n\
EPG_FOUND=false\n\
for location in "${EPG_LOCATIONS[@]}"; do\n\
    if [ -f "$location" ]; then\n\
        echo "Found EPG data at: $location"\n\
        EPG_FOUND=true\n\
        break\n\
    fi\n\
done\n\
\n\
if [ "$EPG_FOUND" = false ]; then\n\
    echo "No EPG data found. Downloading initial EPG data..."\n\
    echo "This may take 5-8 minutes on first run."\n\
    echo "EPG data will be saved to /home/appuser/.ruvsarpur/ (mounted from host ~/.ruvsarpur/)"\n\
    \n\
    # Try to trigger EPG download by running a simple command\n\
    cd /app && timeout 600 python /app/ruvsarpur/ruvsarpur.py --find "test" --limit 1 > /dev/null 2>&1 || true\n\
    \n\
    # Check if EPG data was created\n\
    if [ -f "/home/appuser/.ruvsarpur/tvschedule.json" ]; then\n\
        echo "EPG data downloaded successfully to /home/appuser/.ruvsarpur/tvschedule.json"\n\
        echo "This data is persistent and will be available on container restart."\n\
    else\n\
        echo "Warning: EPG data may not be available. Downloads may take longer."\n\
        echo "You can manually download EPG data using the web interface."\n\
    fi\n\
else\n\
    echo "EPG data is available and persistent."\n\
    # Check if we can write to the EPG directory\n\
    if [ ! -w "/home/appuser/.ruvsarpur" ]; then\n\
        echo "Warning: Cannot write to EPG directory. EPG updates may fail."\n\
        echo "This is likely a permissions issue from previous container runs."\n\
        echo "To fix: rm -rf ~/.ruvsarpur && docker-compose restart"\n\
    fi\n\
fi\n\
\n\
# Start FastAPI backend in background\n\
cd /app && python -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8001 --workers 1 &\n\
\n\
# Wait a moment for backend to start\n\
sleep 2\n\
\n\
# Start Flask frontend\n\
cd /app && python app.py\n\
' > /app/start.sh && chmod +x /app/start.sh && \
    chown appuser:appuser /app/start.sh

# Switch to non-root user
USER root

# Expose ports
EXPOSE 5000 8001

# Set environment variables
ENV PYTHONPATH=/app:/app/ruvsarpur
ENV RUVSARPUR_PATH=/app/ruvsarpur

# Run the startup script
CMD ["/app/start.sh"] 