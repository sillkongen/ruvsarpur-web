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

# Create necessary directories for the non-root user
RUN mkdir -p /home/appuser/.ruvsarpur && \
    chown appuser:appuser /home/appuser/.ruvsarpur

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
    python-levenshtein \
    flask \
    fastapi \
    uvicorn

# Copy the application code (including ruvsarpur)
COPY . /app/

# Create necessary directories and set all permissions properly
RUN mkdir -p /app/backend/downloads /app/data /app/data/.ruvsarpur && \
    chmod -R 777 /app/backend/downloads && \
    chmod +x /app/ruvsarpur/ruvsarpur.py && \
    chown -R appuser:appuser /app && \
    chmod -R 755 /app

# Copy and set up entrypoint script
COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh && \
    chown appuser:appuser /app/entrypoint.sh

# Switch to non-root user
USER appuser

# Expose ports
EXPOSE 5000 8001

# Set environment variables
ENV PYTHONPATH=/app:/app/backend:/app/ruvsarpur
ENV RUVSARPUR_PATH=/app/ruvsarpur
ENV RUVSARPUR_SCRIPT=/app/ruvsarpur/ruvsarpur.py
ENV HOME=/home/appuser
ENV FLASK_ENV=production
ENV SCHEDULE_FILE=/home/appuser/.ruvsarpur/tvschedule.json
ENV SCHEDULE_FILE_FALLBACK=/app/data/.ruvsarpur/tvschedule.json
ENV BACKEND_URL=http://localhost:8001

# Run the entrypoint script
CMD ["/app/entrypoint.sh"] 