# Use Python 3.11 slim as base
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ffmpeg \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create app directory and set permissions
WORKDIR /app

# Copy application code
COPY . /app/

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Set environment variables
ENV PYTHONPATH=/app:/app/ruvsarpur
ENV RUVSARPUR_PATH=/app/ruvsarpur
ENV FLASK_ENV=production

# Copy and set permissions for entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Expose ports
EXPOSE 5000 8001

# Set entrypoint
ENTRYPOINT ["/app/entrypoint.sh"] 