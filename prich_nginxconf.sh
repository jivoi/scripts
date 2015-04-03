#!/bin/sh

BACKUP=`mktemp /tmp/nginx.conf.backup.XXXXXX`
[ -f /usr/local/nginx/conf/nginx.conf ] && CONFIG=/usr/local/nginx/conf/nginx.conf && NGINX=/usr/local/nginx/sbin/nginx
[ -f /usr/local/etc/nginx/nginx.conf ] && CONFIG=/usr/local/etc/nginx/nginx.conf && NGINX=/usr/local/sbin/nginx

TAB=0
cp $CONFIG $BACKUP && echo "Saved as $BACKUP"
cat $BACKUP | while read line; do
        i=0
        echo "$line" | egrep -v "^#" | grep -q '{' && TAB=`expr $TAB + 1` && i=1
        echo "$line" | egrep -v "^#" | grep -q '}' && TAB=`expr $TAB - 1`
        while [ $i -lt $TAB ]; do
                printf "\t"
                i=`expr $i + 1`
        done
        echo "$line"
done > $CONFIG

$NGINX -t && echo "Config ok"