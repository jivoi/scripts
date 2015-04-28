#!/bin/bash
clear
while true; do
echo "Enter Network Configuration"
echo "---------------------------"
echo " "

echo -en "Enter the Hostname? : "
read host

echo -en "Enter the IP Address? : "
read ip

echo -en "Enter the Netmask? : "
read netmask

echo -en "Enter the Gateway? : "
read gateway

echo -e ""
echo -e "Please Review Your Entries "
echo -e "--------------------------"
echo -e "Hostname : $host"
echo -e "IP Address : $ip"
echo -e "Netmask : $netmask"
echo -e "Gateway : $gateway"
echo -e " "
echo -en "Does Everything Look Correct? (y/n) "
read yn
case $yn in
y* | Y* ) line="network --bootproto=static --device=eth0 --gateway=$gateway --ip=$ip --nameserver=8.8.8.8 --netmask=$netmask --onboot=on --hostname $host --noipv6"

ks="/www/ks.example.ru/htdocs/ks.cfg"

sed -e "/^network/s/^network.*/$line/" $ks | sed -e "s/default.example.ru/$host/" > ${ks}.tmp && mv ${ks}.tmp $host.cfg;
echo -e " ";
echo "To Install Your System Use This Command: linux ks=http://ks.example.ru:/$host.cfg ip=$ip gateway=$gateway dns=8.8.8.8"; 
echo "--------------------------";
break;;
[nN]* ) echo -e "Renter Your Information" ; continue;;
q* ) exit ;;
* ) echo "Enter yes or no" ;;
esac
done
