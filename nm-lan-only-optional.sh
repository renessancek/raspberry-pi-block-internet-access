#!/bin/bash
# OPTIONAL: NetworkManager ohne Default-Gateway (zweite Schicht)
# DHCP-Adresse behalten, aber never-default — Internet braucht dann
# zusätzlich explizites Gateway beim Online-Schalten.
set -euo pipefail
CFG="${1:-/etc/lan-only/config}"
# shellcheck source=/dev/null
source "$CFG"
: "${NM_CONNECTION:?}" "${GATEWAY:?}"

echo "Connection: $NM_CONNECTION"
nmcli -g connection.id connection show "$NM_CONNECTION" >/dev/null

# IPv4: nie Default-Route aus DHCP; IPv6 aus (Leak vermeiden)
nmcli connection modify "$NM_CONNECTION" \
  ipv4.never-default yes \
  ipv6.method disabled

nmcli connection up "$NM_CONNECTION"
echo "NM: never-default=yes, IPv6 disabled"
echo "Zum temporären Online-Schalten zusätzlich Gateway setzen, z.B.:"
echo "  sudo nmcli connection modify \"$NM_CONNECTION\" ipv4.gateway $GATEWAY ipv4.never-default no"
echo "  sudo nmcli connection up \"$NM_CONNECTION\""
echo "Danach wieder never-default und Gateway leeren — oder einfach bei nftables bleiben."
