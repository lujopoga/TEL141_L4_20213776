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

TAP="${VM}_tap"
DISK="${VM}.qcow2"
BASE="cirros-0.5.1-x86_64-disk.img"

# Buscar y detener la VM usando su puerto VNC
PID=$(pgrep -f "qemu-system-x86_64.*-vnc 0.0.0.0:${VNC}")

if [ -n "$PID" ]; then
    sudo kill "$PID"
    echo "VM $VM detenida."
else
    echo "No se encontro una VM ejecutandose en el puerto VNC $VNC."
fi

# Eliminar el puerto TAP del OVS
if sudo ovs-vsctl port-to-br "$TAP" > /dev/null 2>&1; then
    sudo ovs-vsctl del-port "$OVS" "$TAP"
fi

# Eliminar interfaz TAP
if ip link show "$TAP" > /dev/null 2>&1; then
    sudo ip link del "$TAP"
fi

# Eliminar disco de la VM
if [ -f "$DISK" ]; then
    rm -f "$DISK"
    echo "Disco $DISK eliminado."
fi

# Eliminar imagen base si ya no existen discos derivados
DELTAS=$(find . -maxdepth 1 -name "*.qcow2" | wc -l)

if [ "$DELTAS" -eq 0 ] && [ -f "$BASE" ]; then
    rm -f "$BASE"
    echo "Imagen base eliminada porque ya no existen discos derivados."
fi

echo "Recursos de $VM eliminados."
