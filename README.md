# raspberry-pi-block-internet-access

LAN-only networking for Raspberry Pi (Debian / Raspberry Pi OS **Trixie**): no internet by default, local network only. Briefly enable internet for updates (`net-online` / `net-offline`) using **nftables**.

## Idea

- **Normal:** outbound traffic only to private networks (LAN). No internet.
- **Updates:** `sudo net-online` → `apt update` / `upgrade` → `sudo net-offline`
- After reboot, LAN-only again (`/etc/nftables.conf` = LAN profile)
- Optional: NetworkManager without a default gateway + IPv6 disabled (second layer)

## Quick start

1. Edit `config` (`LAN_CIDR`, `GATEWAY`, and if needed `NM_CONNECTION` from `nmcli -t -f NAME connection show`)
2. On the Pi:

```bash
sudo ./install.sh
sudo net-status
```

Expected: `ping 1.1.1.1` fails; ping/SSH to other hosts on the LAN still works.

## Updates

```bash
sudo net-online
sudo apt update && sudo apt full-upgrade
sudo net-offline
```

## Files

| File | Role |
|------|------|
| `config` | Subnet, gateway, NM connection name, SSH port |
| `gen-nftables.sh` | Generates LAN and online rulesets |
| `install.sh` | Installs scripts and enables nftables |
| `net-online` / `net-offline` / `net-status` | Toggle helpers |
| `nm-lan-only-optional.sh` | Optional: NM never-default, IPv6 off |

After install, generated rules live at `/etc/nftables-lan.conf`, `/etc/nftables-online.conf`, with boot default `/etc/nftables.conf`.

## Changing config

```bash
sudoedit /etc/lan-only/config
sudo gen-nftables-lan-only
sudo net-offline
```

## Rollback

```bash
sudo nft flush ruleset
sudo systemctl disable --now nftables
```

## Notes

- Raspberry Pi OS from Bookworm/Trixie uses **NetworkManager** (not dhcpcd).
- Filter IPv6 as well, or disable it on the NM profile — otherwise traffic can leak past the IPv4 filter.
- Keep an SSH session open and test from a second device on the LAN before you lock yourself out.

Example `config` in this repo: `192.168.0.0/24` / gateway `192.168.0.1` — adjust to your network.

## License

[GNU General Public License v3.0](LICENSE) (GPL-3.0).
