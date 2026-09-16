#!/bin/bash
# Install lan-only on the Pi (as root)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run with sudo: sudo ./install.sh" >&2
  exit 1
fi

if [[ ! -f "$ROOT/config" ]]; then
  echo "config missing next to install.sh" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$ROOT/config"
echo "LAN_CIDR=$LAN_CIDR  GATEWAY=$GATEWAY  SSH_PORT=$SSH_PORT"

apt-get update -qq
apt-get install -y nftables

install -d -m 0755 /etc/lan-only
install -m 0644 "$ROOT/config" /etc/lan-only/config
install -m 0755 "$ROOT/gen-nftables.sh" /usr/local/sbin/gen-nftables-lan-only
install -m 0755 "$ROOT/net-online" /usr/local/sbin/net-online
install -m 0755 "$ROOT/net-offline" /usr/local/sbin/net-offline
install -m 0755 "$ROOT/net-status" /usr/local/sbin/net-status
install -m 0755 "$ROOT/nm-lan-only-optional.sh" /usr/local/sbin/nm-lan-only-optional

/usr/local/sbin/gen-nftables-lan-only /etc/lan-only/config /etc

# Load rules and enable on boot
systemctl enable nftables
systemctl restart nftables

echo
echo "Done. Check status: sudo net-status"
echo "Updates:          sudo net-online && sudo apt update && sudo apt full-upgrade && sudo net-offline"
echo "Change config:    sudoedit /etc/lan-only/config && sudo gen-nftables-lan-only && sudo net-offline"
echo
echo "Optional second layer (NM without default GW): sudo nm-lan-only-optional"
echo "Before enabling: keep an SSH session open and test from a second device on the LAN."
