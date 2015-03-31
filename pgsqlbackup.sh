#!/bin/sh

HOST=example.ru
BASEDIR=/www/backup
BASES=`psql -U root -h ${HOST} -d postgres --tuples-only -c '\l' | awk -F\| '{ print $1 }' | grep -E -v '(template0|template1)'` 

for base in $BASES; do
        #make directory if not existant
        if [ ! -d $BASEDIR/$base ]; then
                mkdir $BASEDIR/$base
        fi
        if ( nice -n 19 pg_dump -C -F c -h ${HOST} -U root $base \
                > $BASEDIR/$base/$base.`date +%w`.custom.sql ) 2>&1 | grep -E '^.+'; then
                printf "(relevant db: $base)\n\n"
        fi
#printf "${base}\n"
done
pg_dumpall  -U root -h ${HOST} -g |  gzip -9 -c > $BASEDIR/system.`date +%w`.gz

