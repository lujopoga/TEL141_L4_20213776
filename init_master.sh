#!/bin/bash

if [ "$#" -lt 1 ]; then
    echo "Uso: $0 interfaz1 [interfaz2 ...]"
    exit 1
fi

BRIDGE="br-int"

if ! sudo ovs-vsctl br-exists "$BRIDGE"; then
    sudo ovs-vsctl add-br "$BRIDGE"
    echo "Bridge $BRIDGE creado."
else
    echo "Bridge $BRIDGE ya existe."
fi

# Se agrega las interfaces recibidas como parámetros
for INTERFAZ in "$@"; do
    if ip link show "$INTERFAZ" > /dev/null 2>&1; then
        if ! sudo ovs-vsctl port-to-br "$INTERFAZ" > /dev/null 2>&1; then
            sudo ovs-vsctl add-port "$BRIDGE" "$INTERFAZ"
            echo "$INTERFAZ conectada a $BRIDGE."
        else
            echo "$INTERFAZ ya pertenece a un bridge OVS."
        fi
    else
        echo "La interfaz $INTERFAZ no existe."
    fi
done

# Se activa IPv4 forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Política por defecto de FORWARD en DROP
sudo iptables -P FORWARD DROP

echo "Inicialización del master completada."
