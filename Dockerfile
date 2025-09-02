# OctoApp Companion Docker Container
FROM python:3.11-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    zlib1g-dev \
    libjpeg-dev \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Create virtual environment
ENV OCTOAPP_ENV=/app/octoapp-env
RUN python3 -m venv ${OCTOAPP_ENV}

# Copy requirements files
COPY requirements.txt requirements_try.txt ./

# Install Python dependencies
RUN ${OCTOAPP_ENV}/bin/pip install --upgrade pip && \
    ${OCTOAPP_ENV}/bin/pip install --no-cache-dir -r requirements.txt && \
    ${OCTOAPP_ENV}/bin/pip install --no-cache-dir -r requirements_try.txt || echo "Optional deps failed, continuing..."

# Runtime stage
FROM python:3.11-slim

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    python3-pil \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash --uid 1000 octoapp

# Set working directory
WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /app/octoapp-env /app/octoapp-env

# Copy application code
COPY --chown=octoapp:octoapp . .

# Set environment variables
ENV PYTHONPATH=/app \
    PATH="/app/octoapp-env/bin:$PATH" \
    MOONRAKER_URL=http://host.docker.internal:7125 \
    MOONRAKER_PORT=7125

# Create necessary directories with proper permissions
RUN mkdir -p /app/data /app/config /app/logs && \
    chown -R octoapp:octoapp /app

# Switch to non-root user
USER octoapp

# Create startup script that generates config and starts the app
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Get Moonraker connection details from environment variables\n\
MOONRAKER_IP=${MOONRAKER_URL#http://}\n\
MOONRAKER_IP=${MOONRAKER_IP#https://}\n\
MOONRAKER_IP=${MOONRAKER_IP%:*}\n\
MOONRAKER_PORT=${MOONRAKER_PORT:-7125}\n\
\n\
# Validate required environment variables\n\
if [ -z "$MOONRAKER_IP" ] || [ "$MOONRAKER_IP" = "host.docker.internal" ]; then\n\
    echo "ERROR: Please set MOONRAKER_URL environment variable to your Moonraker instance"\n\
    echo "Example: MOONRAKER_URL=http://192.168.1.100:7125"\n\
    exit 1\n\
fi\n\
\n\
# Create companion configuration file\n\
mkdir -p /app/config\n\
cat > /app/config/octoapp.conf << EOF\n\
[companion]\n\
ip_or_hostname = ${MOONRAKER_IP}\n\
port = ${MOONRAKER_PORT}\n\
EOF\n\
\n\
echo "Created companion config with Moonraker at ${MOONRAKER_IP}:${MOONRAKER_PORT}"\n\
\n\
# Generate service configuration JSON\n\
CONFIG_JSON="{\"ServiceName\":\"octoapp-companion\",\"VirtualEnvPath\":\"/app/octoapp-env\",\"RepoRootFolder\":\"/app\",\"LocalFileStoragePath\":\"/app/data\",\"ConfigFolder\":\"/app/config\",\"LogFolder\":\"/app/logs\",\"IsCompanion\":true}"\n\
CONFIG_B64=$(echo -n "$CONFIG_JSON" | base64 -w 0)\n\
\n\
exec python3 -B -m moonraker_octoapp "$CONFIG_B64"\n' > /app/start.sh && \
chmod +x /app/start.sh

# Add labels for better maintainability
LABEL org.opencontainers.image.title="OctoApp Klipper Companion" \
      org.opencontainers.image.description="OctoApp Companion for remote Klipper/Moonraker monitoring ONLY. Not for OctoPrint or direct installation." \
      org.opencontainers.image.source="https://github.com/nilava/OctoApp-Plugin" \
      org.opencontainers.image.vendor="OctoApp" \
      org.opencontainers.image.licenses="AGPL-3.0"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD pgrep -f "moonraker_octoapp" > /dev/null || exit 1

# Run the OctoApp Companion
CMD ["/app/start.sh"]