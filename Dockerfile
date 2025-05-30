FROM python:3.12-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    curl \
    && rm -rf /var/lib/apt/lists/*

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

# Copy the application code
COPY . /app/

# Create necessary directories
RUN mkdir -p /app/downloads /app/data /app/ruvsarpur

# Create startup script
RUN echo '#!/bin/bash\n\
# Check if ruvsarpur source is available\n\
if [ ! -f "/app/ruvsarpur/ruvsarpur.py" ]; then\n\
    echo "Warning: ruvsarpur.py not found at /app/ruvsarpur/ruvsarpur.py"\n\
    echo "Make sure to mount the ruvsarpur source code as a volume:"\n\
    echo "  - ../ruv-container/ruvsarpur/src:/app/ruvsarpur"\n\
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
' > /app/start.sh && chmod +x /app/start.sh

# Expose ports
EXPOSE 5000 8001

# Set environment variables
ENV PYTHONPATH=/app:/app/ruvsarpur
ENV RUVSARPUR_PATH=/app/ruvsarpur

# Run the startup script
CMD ["/app/start.sh"] 