#!/bin/bash

# $1 = VLAN ID
# $2 = Red en formato CIDR

if [ "$#" -ne 2 ]; then
    echo "Uso: $0 VLAN_ID RED_CIDR"
    exit 1
fi

VLAN=$1
RED=$2

GW_IF="gw_vlan${VLAN}"
WAN_IF="ens3"

# Permitir trafico desde la VLAN hacia Internet
sudo iptables -C FORWARD -i "$GW_IF" -o "$WAN_IF" -j ACCEPT 2>/dev/null ||
sudo iptables -A FORWARD -i "$GW_IF" -o "$WAN_IF" -j ACCEPT

# Permitir trafico de respuesta
sudo iptables -C FORWARD -i "$WAN_IF" -o "$GW_IF" \
    -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null ||
sudo iptables -A FORWARD -i "$WAN_IF" -o "$GW_IF" \
    -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# Realizar NAT
sudo iptables -t nat -C POSTROUTING -s "$RED" -o "$WAN_IF" \
    -j MASQUERADE 2>/dev/null ||
sudo iptables -t nat -A POSTROUTING -s "$RED" -o "$WAN_IF" \
    -j MASQUERADE

echo "Acceso a Internet habilitado para VLAN $VLAN ($RED)."
