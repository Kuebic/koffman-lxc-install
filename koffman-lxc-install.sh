#!/usr/bin/env bash

# Koffan Standalone Installation Script
# Run this inside a fresh Debian 12 LXC container
# Usage: bash koffan-standalone.sh

set -euo pipefail

# Colors for output
RD='\033[0;31m'
GN='\033[0;32m'
YW='\033[0;33m'
BL='\033[0;34m'
CL='\033[0m'

function msg_info() {
  echo -e "${BL}[INFO]${CL} $1"
}

function msg_ok() {
  echo -e "${GN}[OK]${CL} $1"
}

function msg_error() {
  echo -e "${RD}[ERROR]${CL} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
  msg_error "This script must be run as root"
  exit 1
fi

# Prompt for password
echo ""
echo -e "${YW}Koffan Shopping List Installer${CL}"
echo "================================"
echo ""
read -rp "Enter Koffan password [shopping123]: " KOFFAN_PASSWORD
KOFFAN_PASSWORD=${KOFFAN_PASSWORD:-shopping123}

read -rp "Enter port [3000]: " KOFFAN_PORT
KOFFAN_PORT=${KOFFAN_PORT:-3000}

read -rp "Enter default language (en/pl/de/es/fr/pt/uk/no/lt) [en]: " KOFFAN_LANG
KOFFAN_LANG=${KOFFAN_LANG:-en}

echo ""
msg_info "Starting Koffan installation..."

# Update system
msg_info "Updating system packages"
apt-get update -qq
apt-get upgrade -y -qq
msg_ok "System updated"

# Install dependencies
msg_info "Installing dependencies"
apt-get install -y -qq curl git sqlite3 ca-certificates wget
msg_ok "Dependencies installed"

# Install Go
GO_VERSION="1.22.5"
msg_info "Installing Go ${GO_VERSION}"
cd /tmp
wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
rm -rf /usr/local/go
tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
rm "go${GO_VERSION}.linux-amd64.tar.gz"

# Add Go to PATH permanently
if ! grep -q '/usr/local/go/bin' /etc/profile; then
  echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
fi
export PATH=$PATH:/usr/local/go/bin
msg_ok "Go ${GO_VERSION} installed"

# Clone and build Koffan
msg_info "Cloning Koffan repository"
mkdir -p /opt
cd /opt
if [[ -d /opt/koffan ]]; then
  rm -rf /opt/koffan
fi
git clone --depth 1 https://github.com/PanSalut/Koffan.git koffan
cd koffan
msg_ok "Repository cloned"

msg_info "Building Koffan (this may take a minute)"
/usr/local/go/bin/go build -ldflags="-s -w" -o koffan .
msg_ok "Koffan built successfully"

# Create data directory
mkdir -p /opt/koffan/data

# Create environment file
msg_info "Creating configuration"
cat <<EOF >/etc/koffan.env
# Koffan Configuration
APP_ENV=production
APP_PASSWORD=${KOFFAN_PASSWORD}
PORT=${KOFFAN_PORT}
DB_PATH=/opt/koffan/data/shopping.db
DEFAULT_LANG=${KOFFAN_LANG}
LOGIN_MAX_ATTEMPTS=5
LOGIN_WINDOW_MINUTES=15
LOGIN_LOCKOUT_MINUTES=30
DISABLE_AUTH=false
EOF
chmod 600 /etc/koffan.env
msg_ok "Configuration created at /etc/koffan.env"

# Create systemd service
msg_info "Creating systemd service"
cat <<EOF >/etc/systemd/system/koffan.service
[Unit]
Description=Koffan Shopping List
Documentation=https://github.com/PanSalut/Koffan
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/koffan
EnvironmentFile=/etc/koffan.env
ExecStart=/opt/koffan/koffan
Restart=always
RestartSec=5

# Security hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/koffan/data
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable koffan
systemctl start koffan
msg_ok "Service created and started"

# Get IP address
IP=$(hostname -I | awk '{print $1}')

# Clean up
msg_info "Cleaning up"
apt-get -y autoremove -qq
apt-get -y autoclean -qq
msg_ok "Cleanup complete"

echo ""
echo "============================================"
echo -e "${GN}Koffan installation complete!${CL}"
echo "============================================"
echo ""
echo -e "Access URL:    ${BL}http://${IP}:${KOFFAN_PORT}${CL}"
echo -e "Password:      ${YW}${KOFFAN_PASSWORD}${CL}"
echo -e "Config file:   /etc/koffan.env"
echo -e "Data location: /opt/koffan/data/shopping.db"
echo ""
echo "Useful commands:"
echo "  systemctl status koffan   - Check service status"
echo "  systemctl restart koffan  - Restart service"
echo "  journalctl -u koffan -f   - View logs"
echo ""