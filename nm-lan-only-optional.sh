#!/bin/bash
# OPTIONAL: NetworkManager without default gateway (second layer)
# Keep DHCP address, but never-default — internet then also needs
# an explicit gateway when going online.
set -euo pipefail
CFG="${1:-/etc/lan-only/config}"
# shellcheck source=/dev/null
source "$CFG"
: "${NM_CONNECTION:?}" "${GATEWAY:?}"

echo "Connection: $NM_CONNECTION"
nmcli -g connection.id connection show "$NM_CONNECTION" >/dev/null

# IPv4: never take default route from DHCP; IPv6 off (avoid leaks)
nmcli connection modify "$NM_CONNECTION" \
  ipv4.never-default yes \
  ipv6.method disabled

nmcli connection up "$NM_CONNECTION"
echo "NM: never-default=yes, IPv6 disabled"
echo "To go online temporarily, also set a gateway, e.g.:"
echo "  sudo nmcli connection modify \"$NM_CONNECTION\" ipv4.gateway $GATEWAY ipv4.never-default no"
echo "  sudo nmcli connection up \"$NM_CONNECTION\""
echo "Afterwards set never-default again and clear the gateway — or just stick with nftables."
