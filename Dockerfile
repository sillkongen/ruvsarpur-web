# Use Python 3.11 slim as base
FROM python:3.11-slim

# Set build arguments for user ID matching
ARG USER_ID=501
ARG GROUP_ID=501

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ffmpeg \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user
RUN groupadd -g ${GROUP_ID} appuser && \
    useradd -u ${USER_ID} -g ${GROUP_ID} -m appuser

# Create necessary directories
RUN mkdir -p /home/appuser/.ruvsarpur && \
    mkdir -p /app/backend/downloads && \
    mkdir -p /app/data/.ruvsarpur

# Set ownership of directories
RUN chown -R appuser:appuser /home/appuser/.ruvsarpur && \
    chown -R appuser:appuser /app/backend/downloads && \
    chown -R appuser:appuser /app/data/.ruvsarpur

# Set permissions of directories
RUN chmod -R 777 /home/appuser/.ruvsarpur && \
    chmod -R 777 /app/backend/downloads && \
    chmod -R 777 /app/data/.ruvsarpur

# Create app directory and set permissions
WORKDIR /app

# Copy application code
COPY --chown=appuser:appuser . /app/

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Switch to non-root user
USER appuser

# Set environment variables
ENV PYTHONPATH=/app:/app/ruvsarpur
ENV RUVSARPUR_PATH=/app/ruvsarpur
ENV FLASK_ENV=production

# Copy and set permissions for entrypoint script
COPY --chown=appuser:appuser entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Expose ports
EXPOSE 5000 8001

# Set entrypoint
ENTRYPOINT ["/app/entrypoint.sh"] 