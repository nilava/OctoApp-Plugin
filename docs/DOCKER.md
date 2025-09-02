# OctoApp Companion Docker Setup Guide

This guide covers running OctoApp Companion as a Docker container to connect your Klipper/Moonraker printer to the OctoApp mobile app for remote monitoring.

## Overview

**OctoApp Companion** is a background service that connects to your local Moonraker instance and relays printer status, notifications, and telemetry to OctoApp's cloud service. This enables remote monitoring through the mobile app without exposing your printer directly to the internet.

### Key Features
- 🔒 **Secure**: No inbound ports needed, outbound-only connections
- 📱 **Remote monitoring**: Get notifications on your phone from anywhere  
- 🌐 **Multi-architecture**: Supports AMD64, ARM64, and ARM32 (Raspberry Pi)
- ⚡ **Lightweight**: Minimal resource usage
- 🔄 **Auto-restart**: Built-in health checks and restart policies

## Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Moonraker instance running on your network
- OctoApp mobile app ([Android](https://play.google.com/store/apps/details?id=de.crysxd.octoapp) / [iOS](https://apps.apple.com/app/octoapp-for-octoprint/id1658133862))

### Method 1: Docker Compose (Recommended)

1. **Create a docker-compose.yml file:**
```yaml
services:
  octoapp-companion:
    image: ghcr.io/nilava/octoapp-plugin:latest
    container_name: octoapp-companion
    restart: unless-stopped
    environment:
      - MOONRAKER_URL=http://192.168.1.100:7125  # Replace with your Moonraker IP
      - MOONRAKER_PORT=7125                      # Optional: defaults to 7125
    volumes:
      - octoapp-data:/app/data
      - octoapp-config:/app/config
      - octoapp-logs:/app/logs
    healthcheck:
      test: ["CMD", "pgrep", "-f", "moonraker_octoapp"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

volumes:
  octoapp-data:
    driver: local
  octoapp-config:
    driver: local
  octoapp-logs:
    driver: local
```

2. **Start the service:**
```bash
docker-compose up -d
```

3. **Check logs:**
```bash
docker-compose logs -f octoapp-companion
```

### Method 2: Docker Run

```bash
docker run -d \
  --name octoapp-companion \
  --restart unless-stopped \
  -e MOONRAKER_URL=http://192.168.1.100:7125 \
  -v octoapp-data:/app/data \
  -v octoapp-config:/app/config \
  -v octoapp-logs:/app/logs \
  ghcr.io/nilava/octoapp-plugin:latest
```

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `MOONRAKER_URL` | **Yes** | `http://host.docker.internal:7125` | Full URL to your Moonraker instance |
| `MOONRAKER_PORT` | No | `7125` | Moonraker port (extracted from URL if not set) |

### Volume Mounts

| Container Path | Description |
|---------------|-------------|
| `/app/data` | Persistent application data and state |
| `/app/config` | Configuration files (auto-generated) |
| `/app/logs` | Application log files |

## Network Setup

### Same Host (Docker on printer)
If running Docker on the same machine as Moonraker:
```yaml
environment:
  - MOONRAKER_URL=http://host.docker.internal:7125
```

### Different Host (Recommended)
If running Docker on a separate machine:
```yaml
environment:
  - MOONRAKER_URL=http://192.168.1.100:7125  # Replace with actual Moonraker IP
```

### Network Discovery Issues
If you encounter connectivity issues, try host networking mode:
```yaml
services:
  octoapp-companion:
    # ... other config ...
    network_mode: host
    environment:
      - MOONRAKER_URL=http://localhost:7125
```

## Mobile App Connection

1. **Install OctoApp** on your mobile device
2. **Start the Docker container** with correct Moonraker URL
3. **Open OctoApp** and go to "Add Printer"
4. **Select "Klipper"** as printer type
5. **Wait for auto-discovery** or manually enter your printer details
6. The companion will appear in the app once connected

## Monitoring & Troubleshooting

### Check Container Status
```bash
# View running containers
docker ps

# Check health status
docker inspect --format='{{.State.Health.Status}}' octoapp-companion

# View detailed container info
docker inspect octoapp-companion
```

### View Logs
```bash
# Follow logs in real-time
docker-compose logs -f octoapp-companion

# View last 50 lines
docker-compose logs --tail 50 octoapp-companion

# View logs with timestamps
docker-compose logs -t octoapp-companion
```

### Common Issues

#### 1. "ERROR: Please set MOONRAKER_URL environment variable"
**Solution:** Ensure `MOONRAKER_URL` is set correctly:
```bash
# Check current environment
docker exec octoapp-companion env | grep MOONRAKER

# Update docker-compose.yml with correct IP
MOONRAKER_URL=http://192.168.1.100:7125  # Your actual Moonraker IP
```

#### 2. Connection timeouts to Moonraker
**Possible causes:**
- Wrong IP address in `MOONRAKER_URL`
- Firewall blocking connections
- Moonraker not running or misconfigured

**Solutions:**
```bash
# Test connectivity from host
ping 192.168.1.100
curl http://192.168.1.100:7125/server/info

# Test from inside container
docker exec octoapp-companion curl http://192.168.1.100:7125/server/info
```

#### 3. Container keeps restarting
**Check the logs:**
```bash
docker-compose logs octoapp-companion
```

**Common fixes:**
- Verify Moonraker URL is accessible
- Check volume permissions
- Ensure sufficient disk space

#### 4. No notifications in mobile app
**Verify connection:**
- Container shows "Moonraker connection is ready and stable"  
- Mobile app shows printer as "Online"
- Check notification settings in mobile app

### Resource Usage

The container is designed to be lightweight:
- **RAM**: ~50-100MB typical usage
- **CPU**: <1% on most systems  
- **Storage**: <100MB for application + logs
- **Network**: Outbound HTTPS only, minimal bandwidth

## Advanced Configuration

### Custom Network Bridge
```yaml
services:
  octoapp-companion:
    # ... other config ...
    networks:
      - printer-network

networks:
  printer-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### Resource Limits
```yaml
services:
  octoapp-companion:
    # ... other config ...
    deploy:
      resources:
        limits:
          memory: 128M
          cpus: '0.5'
        reservations:
          memory: 64M
```

### Log Rotation
```yaml
services:
  octoapp-companion:
    # ... other config ...
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## Security Notes

- Container runs as non-root user (`uid 1000`)
- No inbound ports exposed
- All connections are outbound HTTPS to OctoApp's servers
- End-to-end encryption for sensitive data
- Printer network remains isolated

## Updates

### Updating the Container
```bash
# Pull latest image
docker-compose pull

# Restart with new image  
docker-compose up -d

# Remove old images
docker image prune
```

### Automatic Updates
Consider using [Watchtower](https://containrrr.dev/watchtower/) for automatic updates:
```yaml
services:
  # ... octoapp-companion config ...
  
  watchtower:
    image: containrrr/watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: --interval 86400 octoapp-companion  # Check daily
```

## Support

- **GitHub Issues**: [OctoApp Plugin Issues](https://github.com/crysxd/OctoApp-Plugin/issues)
- **App Support**: Use the bug report function in the mobile app
- **Community**: [OctoApp Discord/Forums](https://github.com/crysxd/OctoApp-Plugin/wiki)

For Docker-specific issues, please include:
- Container logs (`docker-compose logs octoapp-companion`)
- Environment details (`docker inspect octoapp-companion`)
- Your `docker-compose.yml` configuration (remove sensitive data)