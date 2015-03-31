#!/bin/sh
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

#Collect ip to block and send them to perl daemon on server.
for ip in `tail -20000 /logs/apache/access_log | grep 'spam' | awk '{print $1}' | sort | uniq -c | sort -g | awk '$1>25{print $2}' | grep -v ^$`;do
        #echo $ip PREVED
        echo $ip PREVED|nc server 7070
done

#Send -HUP to nginx on server
echo "commit MEDVED"|nc server 7070