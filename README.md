
# OctoApp plugin
A plugin providing extra functionality to OctoApp:

- Remote push notification for events like print completion or filament change
- Remote push notifications for your print progress
- Remote push notifications from your Gcode
- Live Activities on iOS
- End-to-end encryption for Android

Get OctoApp on Google Play and the App Store!



[<img src="https://github.com/crysxd/OctoApp-Plugin/blob/1813c8145887d2862373a97279f56f4542c47ee3/images/play-badge.png" width="200">](https://play.google.com/store/apps/details?id=de.crysxd.octoapp&hl=en&gl=US)  [<img src="https://github.com/crysxd/OctoApp-Plugin/blob/1813c8145887d2862373a97279f56f4542c47ee3/images/app-store-badge.png" width="200">](https://apps.apple.com/us/app/octoapp-for-octoprint/id1658133862)

## Installation

### Option 1: Traditional Installation
Please follow the instructions in the [Wiki](https://github.com/crysxd/OctoApp-Plugin/wiki)!

### Option 2: Docker (Companion Mode)
For users who want to run OctoApp Companion in a container to connect to a remote Moonraker instance:

#### Quick Start with Docker Compose
```bash
# Create docker-compose.yml
cat > docker-compose.yml << EOF
services:
  octoapp-companion:
    image: nilava/octoapp-companion:latest
    container_name: octoapp-companion
    restart: unless-stopped
    environment:
      - MOONRAKER_URL=http://192.168.1.100:7125  # Replace with your Moonraker IP
    volumes:
      - octoapp-data:/app/data
      - octoapp-config:/app/config  
      - octoapp-logs:/app/logs

volumes:
  octoapp-data:
  octoapp-config:
  octoapp-logs:
EOF

# Start the companion
docker-compose up -d
```

#### Quick Start with Docker Run
```bash
docker run -d \
  --name octoapp-companion \
  --restart unless-stopped \
  -e MOONRAKER_URL=http://192.168.1.100:7125 \
  -v octoapp-data:/app/data \
  -v octoapp-config:/app/config \
  -v octoapp-logs:/app/logs \
  nilava/octoapp-companion:latest
```

**Replace `192.168.1.100:7125` with your actual Moonraker IP address and port.**

The Docker image supports:
- **Multi-architecture**: `amd64`, `arm64`, `arm/v7` (Raspberry Pi compatible)  
- **Automatic configuration**: Just set `MOONRAKER_URL` environment variable
- **Persistent storage**: Data, config, and logs are preserved across container restarts
- **Health checks**: Container status monitoring built-in

For detailed Docker setup instructions, see [Docker Setup Guide](docs/DOCKER.md).

## Configuration
Nothing to configure! OctoApp will connect automatically to the plugin

## Issues / Rquests
Please use the app's bug report function in case of any issues. Feature requests can go to [GitLab](https://gitlab.com/realoctoapp/octoapp/-/issues/).
