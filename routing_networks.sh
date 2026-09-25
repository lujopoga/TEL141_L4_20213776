#!/bin/bash

# $1 = VLAN ID 1
# $2 = VLAN ID 2

if [ "$#" -ne 2 ]; then
    echo "Uso: $0 VLAN_ID_1 VLAN_ID_2"
    exit 1
fi

VLAN1=$1
VLAN2=$2

IF1="gw_vlan${VLAN1}"
IF2="gw_vlan${VLAN2}"

# Se verifica que existan las interfaces de ambas VLAN
if ! ip link show "$IF1" > /dev/null 2>&1; then
    echo "Error: no existe la interfaz $IF1"
    exit 1
fi

if ! ip link show "$IF2" > /dev/null 2>&1; then
    echo "Error: no existe la interfaz $IF2"
    exit 1
fi

# Se permite trafico VLAN1 -> VLAN2
sudo iptables -C FORWARD -i "$IF1" -o "$IF2" -j ACCEPT 2>/dev/null ||
sudo iptables -A FORWARD -i "$IF1" -o "$IF2" -j ACCEPT

# Se permite trafico VLAN2 -> VLAN1
sudo iptables -C FORWARD -i "$IF2" -o "$IF1" -j ACCEPT 2>/dev/null ||
sudo iptables -A FORWARD -i "$IF2" -o "$IF1" -j ACCEPT

echo "Enrutamiento habilitado entre VLAN $VLAN1 y VLAN $VLAN2."
