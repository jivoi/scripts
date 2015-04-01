#!/bin/bash
IPT=/sbin/iptables
$IPT --flush
$IPT -t nat --flush

# loopback iface
$IPT -A INPUT -i lo -j ACCEPT
$IPT -A INPUT -d 127.0.0.0/8 -j DROP
$IPT -A INPUT -s 127.0.0.0/8 -j DROP

# deny special ipz
$IPT -A INPUT -s 10.0.0.0/8 -j DROP
$IPT -A INPUT -s 172.16.0.0/12 -j DROP
$IPT -A INPUT -s 192.168.0.0/16 -j DROP
$IPT -A INPUT -s 169.254.0.0/16 -j DROP
$IPT -A INPUT -s 224.0.0.0/4 -j DROP
$IPT -A INPUT -s 240.0.0.0/4 -j DROP

# icmp
$IPT -A INPUT -p icmp --icmp-type fragmentation-needed -j DROP
$IPT -A INPUT -p icmp --icmp-type 0 -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type 3 -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type 8 -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type 11 -j ACCEPT

$IPT -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# local ssh
$IPT -A INPUT -p tcp --dport 22 -j ACCEPT

# www
$IPT -A INPUT -p tcp --dport 80 -j ACCEPT
$IPT -A INPUT -p tcp --dport 443 -j ACCEPT

$IPT -A INPUT -j DROP

$IPT -A OUTPUT -j ACCEPT

$IPT -A FORWARD -j DROP
