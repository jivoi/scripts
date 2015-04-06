#!/bin/bash
set -u

BDIR='/mongo_backup/'
EPERIOD=7
DBASE='db1'
LOG='/mongo_backup/backup.log'
#USER=''
#PASSWORD=''

if [ "xfalse" == "x$(mongo --quiet admin --eval 'rs.isMaster().ismaster')" ]; then
    find $BDIR -maxdepth 1 -mindepth 1 -type d -name "2*" -mtime +$EPERIOD -exec rm -rf {} \;
    for i in $DBASE; do
        echo -n "$(date +%d-%m-%y' '%T) " >> $LOG
        /usr/bin/mongodump -h $(hostname -f) -d $i --out "${BDIR}$(date +%Y%m%d)" >> $LOG 2>&1
        [ $? -gt 0 ] && echo "Error backup mongodb database $i" | mail -s "$(hostname) mongodb backup error" root@example.ru
    done
else
    echo "$(date +%d-%m-%y' '%T) isMaster = true, skip backup" >> $LOG
fi
