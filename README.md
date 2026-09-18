# raspberry-pi-block-internet-access

LAN-only networking for Raspberry Pi (Debian / Raspberry Pi OS **Trixie**): no internet by default, local network only. Briefly enable internet for updates (`net-online` / `net-offline`) using **nftables**.

## Idea

- **Normal:** outbound traffic only to private networks (LAN). No internet.
- **Updates:** `sudo net-online` → `apt update` / `upgrade` → `sudo net-offline`
- After reboot, LAN-only again (`/etc/nftables.conf` = LAN profile)
- **Nightly:** systemd timer at midnight opens a short internet window, runs `apt` upgrades, then returns to LAN-only
- Optional: NetworkManager without a default gateway + IPv6 disabled (second layer)

## Quick start

1. Edit `config` (`LAN_CIDR`, `GATEWAY`, and if needed `NM_CONNECTION` from `nmcli -t -f NAME connection show`)
2. On the Pi:

```bash
sudo ./install.sh
sudo net-status
```

Expected: `ping 1.1.1.1` fails; ping/SSH to other hosts on the LAN still works.

## Updates (manual)

```bash
sudo net-online
sudo apt update && sudo apt full-upgrade
sudo net-offline
```

Or one shot:

```bash
sudo net-auto-update
```

## Nightly auto-update

`install.sh` enables a systemd timer that runs daily at **00:00** (Pi local time), with a small random delay (up to 10 minutes):

1. `net-online`
2. `apt-get update` + `full-upgrade` + `autoremove`
3. Always `net-offline` afterwards (even if apt fails), via `trap`

Useful commands:

```bash
systemctl status lan-only-auto-update.timer
systemctl list-timers lan-only-auto-update.timer
journalctl -u lan-only-auto-update.service
sudo systemctl disable --now lan-only-auto-update.timer   # turn off
sudo systemctl enable --now lan-only-auto-update.timer    # turn on again
```

To change the schedule, edit `OnCalendar=` in `/etc/systemd/system/lan-only-auto-update.timer` (or the copy in this repo before install), then:

```bash
sudo systemctl daemon-reload
sudo systemctl restart lan-only-auto-update.timer
```

Debian’s `unattended-upgrades` still needs outbound internet; this timer is the intended way to combine auto-updates with LAN-only networking.

## Files

| File | Role |
|------|------|
| `config` | Subnet, gateway, NM connection name, SSH port, optional `LAN_TCP_PORTS` |
| `gen-nftables.sh` | Generates LAN and online rulesets (`table inet lan_only`) |
| `install.sh` | Installs scripts, enables nftables + nightly timer (keeps existing `/etc/lan-only/config`) |
| `net-online` / `net-offline` / `net-status` | Toggle helpers |
| `net-auto-update` | Online → apt → offline (used by the timer) |
| `lan-only-auto-update.service` / `.timer` | Midnight systemd schedule |
| `nm-lan-only-optional.sh` | Optional: NM never-default, IPv6 off |

After install, generated rules live at `/etc/nftables-lan.conf`, `/etc/nftables-online.conf`, with boot default `/etc/nftables.conf`.


## LAN services (inbound)

The firewall **input** policy is drop. By default only SSH from `LAN_CIDR` is allowed.
Set extra TCP ports in `config`:

```bash
LAN_TCP_PORTS="8080"
```

Then:

```bash
sudo gen-nftables-lan-only
sudo net-offline
```

Multiple ports: `LAN_TCP_PORTS="8080,9090"`. This does not open them to the internet — only from your LAN.

Re-running `sudo ./install.sh` updates scripts and units but leaves `/etc/lan-only/config` alone if it already exists. Existing `/etc/lan-only/config` is **not** overwritten on reinstall; only created if missing.

## Docker

Older versions used `flush ruleset`, which deleted Docker’s `DOCKER` nat/filter chains and broke port publishing (`Unable to enable DNAT rule` / `No chain/target/match`).

Current rules:

- live in **`table inet lan_only` only** (legacy `inet filter` is removed on apply)
- **do not** flush the whole nft ruleset
- **do not** set a `forward` drop policy (Docker needs FORWARD for bridge/DNAT)

After upgrading lan-only once:

```bash
cd /path/to/raspberry-pi-block-internet-access
git pull
sudo ./install.sh
# or: sudo gen-nftables-lan-only && sudo net-offline && sudo systemctl restart docker

cd ~/Dokumente/Projekte/expense_app_web   # example
docker compose up -d
sudo net-status   # should show DOCKER nat chain: OK
```

Ensure `LAN_TCP_PORTS` includes published host ports (e.g. `8080`). Git/`docker pull` still need internet: use `sudo net-online` for those steps, then `sudo net-offline`.

## Changing config

```bash
sudoedit /etc/lan-only/config
sudo gen-nftables-lan-only
sudo net-offline
```

## Rollback

```bash
sudo systemctl disable --now lan-only-auto-update.timer
sudo nft delete table inet lan_only 2>/dev/null || true
sudo nft delete table inet filter 2>/dev/null || true
sudo systemctl disable --now nftables
sudo systemctl restart docker   # if you use Docker
```

## Notes

- Raspberry Pi OS from Bookworm/Trixie uses **NetworkManager** (not dhcpcd).
- Filter IPv6 as well, or disable it on the NM profile — otherwise traffic can leak past the IPv4 filter.
- Keep an SSH session open and test from a second device on the LAN before you lock yourself out.
- Inbound is drop-by-default: only SSH and ports listed in `LAN_TCP_PORTS` (from `LAN_CIDR`) are allowed. Example: `LAN_TCP_PORTS="8080"` for a LAN web UI.
- Ensure the Pi clock/timezone is correct (`timedatectl`) so midnight matches what you expect.

Example `config` in this repo: `192.168.0.0/24` / gateway `192.168.0.1` — adjust to your network.

## License

[GNU General Public License v3.0](LICENSE) (GPL-3.0).
