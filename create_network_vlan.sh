#!/bin/bash

# Parametros:
# $1 = VLAN ID
# $2 = Red en formato CIDR
# $3 = DHCP: on/off
# $4 = Inicio rango DHCP (si DHCP=on)
# $5 = Fin rango DHCP (si DHCP=on)

if [ "$#" -lt 3 ]; then
    echo "Uso: $0 VLAN_ID RED_CIDR DHCP[on/off] [RANGO_INICIO RANGO_FIN]"
    exit 1
fi

VLAN=$1
RED=$2
DHCP=$3

BRIDGE="br-int"
GW_IF="gw_vlan${VLAN}"

NETWORK=$(echo "$RED" | cut -d/ -f1)
PREFIX=$(echo "$RED" | cut -d/ -f2)

IFS='.' read -r A B C D <<< "$NETWORK"

GATEWAY="$A.$B.$C.$((D+1))"

# Crear interfaz interna para la VLAN
sudo ovs-vsctl --may-exist add-port "$BRIDGE" "$GW_IF" \
    tag="$VLAN" -- set interface "$GW_IF" type=internal

sudo ip link set "$GW_IF" up

# Se asigna gateway solo si aun no tiene IPv4
if ! ip -4 addr show "$GW_IF" | grep -q "inet "; then
    sudo ip addr add "$GATEWAY/$PREFIX" dev "$GW_IF"
fi

echo "VLAN $VLAN creada. Gateway: $GATEWAY/$PREFIX"

# Configuracion DHCP
if [ "$DHCP" = "on" ]; then

    if [ "$#" -lt 5 ]; then
        echo "Debe indicar el rango DHCP."
        exit 1
    fi

    DHCP_START=$4
    DHCP_END=$5

    NS="ns-dhcp-vlan${VLAN}"
    DHCP_OVS="dhcp_v${VLAN}"
    DHCP_NS="dhcp_ns${VLAN}"

    # Se crea namespace si no existe
    if ! sudo ip netns list | grep -q "^${NS}"; then
        sudo ip netns add "$NS"

        sudo ip link add "$DHCP_OVS" type veth peer name "$DHCP_NS"

        sudo ovs-vsctl add-port "$BRIDGE" "$DHCP_OVS" tag="$VLAN"

        sudo ip link set "$DHCP_OVS" up
        sudo ip link set "$DHCP_NS" netns "$NS"

        sudo ip netns exec "$NS" ip link set lo up
        sudo ip netns exec "$NS" ip link set "$DHCP_NS" up

        DHCP_IP="$A.$B.$C.$((D+100))"

        sudo ip netns exec "$NS" \
            ip addr add "$DHCP_IP/$PREFIX" dev "$DHCP_NS"
    fi

    # Se inicia el servidor DHCP
    sudo ip netns exec "$NS" dnsmasq \
        --interface="$DHCP_NS" \
        --bind-interfaces \
        --dhcp-range="$DHCP_START","$DHCP_END",12h \
        --dhcp-option=3,"$GATEWAY"

    echo "DHCP habilitado: $DHCP_START - $DHCP_END"
fi

echo "Configuracion terminada."
