#!/bin/bash

# Parametros:
# $1 = Nombre de la VM
# $2 = Nombre del OVS
# $3 = VLAN ID
# $4 = Puerto VNC

if [ "$#" -ne 4 ]; then
    echo "Uso: $0 NOMBRE_VM OVS VLAN_ID PUERTO_VNC"
    exit 1
fi

VM=$1
OVS=$2
VLAN=$3
VNC=$4

BASE="cirros-0.5.1-x86_64-disk.img"
DISK="${VM}.qcow2"
TAP="${VM}_tap"

# Verificar que exista el bridge OVS
if ! sudo ovs-vsctl br-exists "$OVS"; then
    echo "Error: el OVS $OVS no existe."
    exit 1
fi

# Descargar imagen base si no existe
if [ ! -f "$BASE" ]; then
    echo "Descargando imagen base CirrOS..."
    wget http://download.cirros-cloud.net/0.5.1/$BASE

    if [ $? -ne 0 ]; then
        echo "Error al descargar la imagen base."
        exit 1
    fi
fi

# Crear disco de la VM si no existe
if [ ! -f "$DISK" ]; then
    qemu-img create -f qcow2 \
        -b "$BASE" \
        -F qcow2 \
        "$DISK"
fi

# Crear interfaz TAP
if ! ip link show "$TAP" > /dev/null 2>&1; then
    sudo ip tuntap add mode tap name "$TAP"
fi

sudo ip link set "$TAP" up

# Conectar TAP al OVS y asignarla a la VLAN
if ! sudo ovs-vsctl port-to-br "$TAP" > /dev/null 2>&1; then
    sudo ovs-vsctl add-port "$OVS" "$TAP" tag="$VLAN"
else
    sudo ovs-vsctl set port "$TAP" tag="$VLAN"
fi

# Iniciar VM
sudo qemu-system-x86_64 \
    -enable-kvm \
    -vnc 0.0.0.0:"$VNC" \
    -netdev tap,id=net0,ifname="$TAP",script=no,downscript=no \
    -device e1000,netdev=net0 \
    -daemonize \
    "$DISK"

echo "VM $VM creada correctamente."
echo "OVS: $OVS"
echo "VLAN: $VLAN"
echo "TAP: $TAP"
echo "VNC: $VNC"
