#!/bin/bash
# Generiert nftables-lan.conf und nftables-online.conf aus /etc/lan-only/config
set -euo pipefail

CFG="${1:-/etc/lan-only/config}"
OUT_DIR="${2:-/etc}"
mkdir -p "$OUT_DIR"
# shellcheck source=/dev/null
source "$CFG"

: "${LAN_CIDR:?}" "${SSH_PORT:?}" "${PRIVATE_V4:?}"

LAN_CONF="$OUT_DIR/nftables-lan.conf"
ONLINE_CONF="$OUT_DIR/nftables-online.conf"

cat > "$LAN_CONF" << NFEOF
#!/usr/sbin/nft -f
# Generiert von lan-only — nicht von Hand pflegen; Config + gen-nftables.sh nutzen
flush ruleset

table inet filter {
  chain input {
    type filter hook input priority filter; policy drop
    iif "lo" accept
    ct state established,related accept
    ct state invalid drop
    # ICMP Diagnose (optional, rate-limit)
    icmp type echo-request limit rate 5/second accept
    icmpv6 type { echo-request, nd-neighbor-solicit, nd-neighbor-advert, nd-router-solicit, nd-router-advert } accept
    # SSH nur aus dem LAN
    ip saddr $LAN_CIDR tcp dport $SSH_PORT accept
    ip6 saddr fe80::/10 tcp dport $SSH_PORT accept
  }

  chain forward {
    type filter hook forward priority filter; policy drop
  }

  chain output {
    type filter hook output priority filter; policy drop
    oif "lo" accept
    ct state established,related accept
    ct state invalid drop
    # IPv4: private / Link-local
    ip daddr { $PRIVATE_V4 } accept
    # IPv6: Link-local + ULA (kein globales Internet)
    ip6 daddr { fe80::/10, fc00::/7 } accept
    # DHCPv6 / NDP Hilfen
    icmpv6 type { nd-neighbor-solicit, nd-neighbor-advert, nd-router-solicit, nd-router-advert } accept
  }
}
NFEOF

cat > "$ONLINE_CONF" << NFEOF
#!/usr/sbin/nft -f
# Updates-Fenster: LAN-Regeln + freier Outbound
flush ruleset

table inet filter {
  chain input {
    type filter hook input priority filter; policy drop
    iif "lo" accept
    ct state established,related accept
    ct state invalid drop
    icmp type echo-request limit rate 5/second accept
    icmpv6 type { echo-request, nd-neighbor-solicit, nd-neighbor-advert, nd-router-solicit, nd-router-advert } accept
    ip saddr $LAN_CIDR tcp dport $SSH_PORT accept
    ip6 saddr fe80::/10 tcp dport $SSH_PORT accept
  }

  chain forward {
    type filter hook forward priority filter; policy drop
  }

  chain output {
    type filter hook output priority filter; policy accept
    oif "lo" accept
  }
}
NFEOF

# Debian lädt standardmäßig /etc/nftables.conf
cp -f "$LAN_CONF" "$OUT_DIR/nftables.conf"
echo "geschrieben: $LAN_CONF, $ONLINE_CONF, $OUT_DIR/nftables.conf (LAN-Modus)"
