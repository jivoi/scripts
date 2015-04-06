#!/bin/bash

if [[ $# -ne 2 ]]; then
	echo "Use: $0 <VMNAME> <IP>"
	exit 1
fi

#2 задаем константы
HDD_SIZE="10G"
VM_NAME=$1
IP=$2
VG="vg00"
TEMPLATE_PATH="/lxc/template.tar.gz"
TEMPLATE="template.tar.gz"

if [[ -e "/var/lib/lxc/$VM_NAME" ]]; then
	echo "VM alredy exist"
	exit 1
fi

lvcreate -n "$VM_NAME" -L "$HDD_SIZE" "$VG"
if [[ $? -ne 0 ]]; then
	echo "LVM volume for $VM_NAME not created"
	exit 1
fi

mkfs.ext4 /dev/"$VG"/"$VM_NAME"
if [[ $? -ne 0 ]]; then
        echo "FS on $VM_NAME not created"
        exit 1
fi

mkdir /lxc/"$VM_NAME"
if [[ $? -ne 0 ]]; then
        echo "Dir /lxc/$VM_NAME not created"
        exit 1
fi

mount /dev/"$VG"/"$VM_NAME" /lxc/"$VM_NAME" -w
if [[ $? -ne 0 ]]; then
        echo "fail to mount /lxc/$VM_NAME"
        exit 1
fi

cp "$TEMPLATE_PATH" /lxc/"$VM_NAME"
if [[ $? -ne 0 ]]; then
        echo "Default template not created in /lxc/$VM_NAME"
        exit 1
fi

tar zxf /lxc/$VM_NAME/$TEMPLATE -C /lxc/$VM_NAME/
if [[ $? -ne 0 ]]; then
        echo "Cant unpack template in lxc/$VM_NAME"
        exit 1
fi

rm /lxc/"$VM_NAME"/"$TEMPLATE"
if [[ $? -ne 0 ]]; then
        echo "Cant delete templete"
        exit 1
fi

mkdir /var/lib/lxc/"$VM_NAME"/
if [[ $? -ne 0 ]]; then
        echo "Cant create dir for configs"
        exit 1
fi

mv /lxc/$VM_NAME/configclean /var/lib/lxc/"$VM_NAME"/config
if [[ $? -ne 0 ]]; then
        echo "Cant config default config"
        exit 1
fi


sed -i.bak "s/hostnametmp/$VM_NAME/g" /var/lib/lxc/"$VM_NAME"/config

sed -i.bak "s/127.0.0.1/$IP/g" /lxc/$VM_NAME/rootfs/etc/network/interfaces

chattr +i /lxc/$VM_NAME/rootfs/etc/resolv.conf

rm /lxc/$VM_NAME/rootfs/etc/rc0.d/S60umountroot

echo "Ok now run sudo lxc-start -n $VM_NAME -d" 

exit 0

