#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Uso: $0 VLAN_ID RED_CIDR"
    exit 1
fi

VLAN=$1
RED=$2

GW_IF="gw_vlan${VLAN}"
WAN_IF="ens3"

sudo iptables -D FORWARD -i "$GW_IF" -o "$WAN_IF" \
    -j ACCEPT 2>/dev/null || true

sudo iptables -D FORWARD -i "$WAN_IF" -o "$GW_IF" \
    -m conntrack --ctstate RELATED,ESTABLISHED \
    -j ACCEPT 2>/dev/null || true

sudo iptables -t nat -D POSTROUTING -s "$RED" \
    -o "$WAN_IF" -j MASQUERADE 2>/dev/null || true

echo "Acceso a Internet deshabilitado para VLAN $VLAN ($RED)."
