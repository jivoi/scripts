#!/bin/sh

MYSQLHOTCOPY=/root/bin/mysqlhotcopy
BASEDIR=/www/backup
TMPDIR=/www/tmp/backup
KEEPDAYS=7
BASES=`mysql -Be 'show databases' | egrep -v '^(Database|test|information_schema)$'`
#BASES="mysql"
DATE=`date +%Y%m%d`
OWNER='mysql:mysql'
REPLTABLE=mysql.log_pos
ON_SLAVE=YES

find ${BASEDIR} -type f -name '*.gz' -mtime +${KEEPDAYS} | xargs rm

rm -rf ${TMPDIR}
mkdir -p -m 700 ${TMPDIR}

if [ -z ${REPLTABLE} ]; then
	${MYSQLHOTCOPY} -q --addtodest --noindices ${BASES} ${TMPDIR}
else 
	if [ ${ON_SLAVE} = "YES" ]; then
		${MYSQLHOTCOPY} -q --addtodest --noindices \
			--on_slave --record_log_pos=${REPLTABLE} ${BASES} ${TMPDIR}
	else
                ${MYSQLHOTCOPY} -q --addtodest --noindices \
                        --record_log_pos=${REPLTABLE} ${BASES} ${TMPDIR}
	fi
fi

cd ${TMPDIR}
chown -R ${OWNER} .

for base in ${BASES}; do
  if [ ! -d ${BASEDIR}/${base} ]; then
    mkdir -p -m 750 ${BASEDIR}/${base}
  fi

  if [ -d ${TMPDIR}/${base} ]; then
    nice -n 20 tar -czf ${BASEDIR}/${base}/${base}.${DATE}.tar.gz ./${base}
    rm -rf ${TMPDIR}/${base}
  fi
done

rm -rf ${TMPDIR}

#               CREATE TABLE log_pos (
#                 host            varchar(60) NOT null,
#                 time_stamp      timestamp(14) NOT NULL,
#                 log_file        varchar(32) default NULL,
#                 log_pos         int(11)     default NULL,
#                 master_host     varchar(60) NULL,
#                 master_log_file varchar(32) NULL,
#                 master_log_pos  int NULL,
#
#                 PRIMARY KEY  (host)
#               );
