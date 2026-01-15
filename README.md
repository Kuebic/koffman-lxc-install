# Koffan LXC Install Script

Standalone installer for [Koffan](https://github.com/PanSalut/Koffan) shopping list app on Proxmox LXC containers. No Docker required.

## Requirements

- Proxmox VE
- Debian 12 LXC container (256MB RAM, 2GB disk minimum)

## Installation

1. Create a Debian 12 LXC in Proxmox
2. SSH into the container and run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Kuebic/koffman-lxc-install/main/koffan-lxc-install.sh)
```

3. Follow the prompts for password, port, and language

## Configuration

Edit `/etc/koffan.env` to change settings:

```bash
nano /etc/koffan.env
systemctl restart koffan
```

| Variable | Default | Description |
|----------|---------|-------------|
| `APP_PASSWORD` | `shopping123` | Login password |
| `PORT` | `3000` | Web server port |
| `DEFAULT_LANG` | `en` | UI language (en/pl/de/es/fr/pt/uk/no/lt) |
| `DISABLE_AUTH` | `false` | Disable login (for reverse proxy auth) |

## Usage

| Command | Description |
|---------|-------------|
| `systemctl status koffan` | Check status |
| `systemctl restart koffan` | Restart service |
| `journalctl -u koffan -f` | View logs |

## Updating

```bash
cd /opt/koffan
git pull
/usr/local/go/bin/go build -ldflags="-s -w" -o koffan .
systemctl restart koffan
```

## File Locations

- App: `/opt/koffan/`
- Database: `/opt/koffan/data/shopping.db`
- Config: `/etc/koffan.env`
- Service: `/etc/systemd/system/koffan.service`

## License

MIT
