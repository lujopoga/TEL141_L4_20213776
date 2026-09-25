#!/bin/bash

BRIDGE="br-int"

if [ "$#" -lt 1 ]; then
    echo "Uso: $0 INTERFAZ [INTERFAZ...]"
    exit 1
fi

# Se crea br-int si no existe
if ! sudo ovs-vsctl br-exists "$BRIDGE"; then
    sudo ovs-vsctl add-br "$BRIDGE"
    echo "Bridge $BRIDGE creado."
else
    echo "Bridge $BRIDGE ya existe."
fi

# Se agrega las interfaces indicadas al bridge
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

echo "Inicialización del worker completada."
