#!/bin/sh

ipfw=`which ipfw`" -q"
extif='em0'

if [ "$1" = "echo" ]; then
    ipfw=`which echo`
else
    ipfw=`which ipfw`" -q"
fi

rule_num=1000

pass ()
{
    rule_num=$(($rule_num+10))
    $ipfw add $rule_num allow $*
}

count ()
{
    rule_num=$(($rule_num+10))
    $ipfw add $rule_num count $*
}

deny ()
{
    rule_num=$(($rule_num+10))
    $ipfw add $rule_num deny $*
}

any ()
{
    pass all from $* to any
    pass all from any to $*
}

$ipfw -f flush

# loopback iface
pass ip from any to any via lo0
deny ip from any to 127.0.0.0/8
deny ip from 127.0.0.0/8 to any

# deny
deny ip from me to any in recv ${extif}

# deny special ip
deny ip from { 10.0.0.0/8 or 172.16.0.0/12 or 192.168.0.0/16 or 169.254.0.0/16 or 224.0.0.0/4 or 240.0.0.0/4 } to any

# icmp
deny icmp from any to any frag
pass icmp from any to any icmptype 0,3,8,11

#fast tcp established
pass tcp from any to any established

# local ssh
pass tcp from any to me 22 setup

# www
pass tcp from any to me 80,443 setup

# connections from me
pass tcp from me to any setup keep-state
pass udp from me to any keep-state

rule_num=64990
deny ip from any to any
