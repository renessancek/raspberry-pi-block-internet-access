# raspberry-pi-block-internet-access

LAN-only Networking für Raspberry Pi (Debian / Raspberry Pi OS **Trixie**): standardmäßig kein Internet, nur lokales Netz. Internet kurz freischalten für Updates (`net-online` / `net-offline`) via **nftables**.

## Idee

- **Normal:** Outbound nur zu privaten Netzen (LAN). Kein Internet.
- **Updates:** `sudo net-online` → `apt update` / `upgrade` → `sudo net-offline`
- Nach Reboot wieder LAN-only (`/etc/nftables.conf` = LAN-Profil)
- Optional: NetworkManager ohne Default-Gateway + IPv6 aus (zweite Schicht)

## Schnellstart

1. `config` anpassen (`LAN_CIDR`, `GATEWAY`, ggf. `NM_CONNECTION` aus `nmcli -t -f NAME connection show`)
2. Auf dem Pi:

```bash
sudo ./install.sh
sudo net-status
```

Erwartung: `ping 1.1.1.1` failt, Ping/SSH zu anderen Hosts im LAN geht.

## Updates

```bash
sudo net-online
sudo apt update && sudo apt full-upgrade
sudo net-offline
```

## Dateien

| Datei | Rolle |
|-------|--------|
| `config` | Subnetz, Gateway, NM-Name, SSH-Port |
| `gen-nftables.sh` | erzeugt LAN- und Online-Rulesets |
| `install.sh` | installiert Scripts + aktiviert nftables |
| `net-online` / `net-offline` / `net-status` | Umschalter |
| `nm-lan-only-optional.sh` | optional: NM never-default, IPv6 off |

Nach Install landen die generierten Rules unter `/etc/nftables-lan.conf`, `/etc/nftables-online.conf`, Boot-Default `/etc/nftables.conf`.

## Config ändern

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

## Hinweise

- Raspberry Pi OS ab Bookworm/Trixie nutzt **NetworkManager** (nicht dhcpcd).
- IPv6 mitfiltern oder im NM-Profil deaktivieren — sonst Leak am IPv4-Filter vorbei.
- SSH-Session offen lassen und von einem zweiten Gerät im LAN testen, bevor du dich aussperrst.

Beispiel-`config` in diesem Repo: `192.168.0.0/24` / Gateway `192.168.0.1` — an dein Netz anpassen.

## Lizenz

[GNU General Public License v3.0](LICENSE) (GPL-3.0).
