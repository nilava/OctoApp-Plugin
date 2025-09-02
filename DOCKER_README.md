# OctoApp Companion Docker Fork ✅

Your Docker-enabled fork is ready at: **https://github.com/nilava/OctoApp-Plugin**

## 🐳 What This Provides:
- **OctoApp Companion ONLY** (for connecting to remote Moonraker)
- **GitHub Container Registry**: `ghcr.io/nilava/octoapp-companion:latest`
- **Multi-platform builds**: AMD64, ARM64, ARMv7
- **Automatic upstream sync**: Every 6 hours

## ⚠️ Important Usage Notes:
- **For Companion mode only** - connects to remote Moonraker device
- **NOT for traditional plugin installation** - use `install.sh` for that
- Use when you want OctoApp monitoring on a separate device from your printer

## 📋 Users can now run:
```bash
# Replace with your REMOTE Moonraker IP
docker run -d -e MOONRAKER_URL=http://192.168.1.100:7125 \
  ghcr.io/nilava/octoapp-companion:latest
```

## 🔄 Next Steps (Optional):
1. Monitor build at: https://github.com/nilava/OctoApp-Plugin/actions
2. Add Docker Hub support later by adding `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets