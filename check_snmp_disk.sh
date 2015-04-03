#!/usr/local/bin/bash

# This script takes:
# <host> <community> <mountpoint> <megs>

snmpwalk=/usr/local/bin/snmpwalk
snmpget=/usr/local/bin/snmpget

calc_free()
# takes <size> <used> <allocation>
{
if result=`echo "($1*$3*.92/1024-$2*$3/1024)/1024" | bc`
then
echo "$result"
else
echo "DISK UNKNOWN: Cant calculate free space."
exit 3
fi
}

fetch_details()
#takes <host> <community> <index>
{
if result=`$snmpget -v2c -c $2 -OqvU $1 hrStorageSize.$3 hrStorageUsed.$3 hrStorageAllocationUnits.$3 | while read oid ; do printf "$oid " ; done`
then
echo "$result"
else
echo "DISK UNKNOWN: Cant fetch details."
exit 3
fi
}

if result=`$snmpwalk -v2c -c $2 -Oqs $1 hrStorageDescr | grep "$3$"`
then
index=`echo $result | sed 's/hrStorageDescr\.//' | sed 's/ .*//'`

details=`fetch_details $1 $2 $index`

free=`calc_free $details`

if [ "$free" -gt "$4" ]
then
echo "DISK OK: mount $3 free $free MB."
exit 0
else
echo "DISK CRITICAL: mount $3 free $free MB."
exit 2
fi
else
echo "DISK UNKNOWN: $3 dosent exist or snmp isent responding."
exit 3
fi