#!/bin/sh
###################################
REPLICATION="YES"
ONSLAVE="YES"
KEEPDAYS=7
BASEDIR=/www/backup
TMPDIR=/www/tmp/backup
DEBUG="0"
###################################

OS=`uname`
SOCKET=/tmp

if [ $OS = "Linux" ]; then SOCKET=/var/lib/mysql; fi 
if [ -z "${1}" ]; then SOCKET=${SOCKET}/mysql.sock; else SOCKET=${SOCKET}/$1; fi

REPL_TABLE="log_pos_"
MYSQL="mysql -S ${SOCKET}"
MYSQLHOTCOPY="/root/bin/mysqlhotcopy -S ${SOCKET}"
MYSQLDUMP="mysqldump -S ${SOCKET}"
BASES=`${MYSQL} -Be 'show databases' | egrep -v '^(Database|information_schema)$'`
#BASES="mysql"
DATE=`date +%Y%m%d`
OWNER='mysql:mysql'

XARGS="xargs"
if [ $OS = "Linux" ]; then XARGS="xargs -r"; fi
find ${BASEDIR} -type f -name '*.gz' -mtime +${KEEPDAYS} | ${XARGS} -r rm

rm -rf ${TMPDIR}
mkdir -p -m 700 ${TMPDIR}

for i in ${BASES}; do
  TABLESCOUNT=`${MYSQL} -Be 'show tables\g' ${i} | wc -l`
  if [ $DEBUG = "1" ]; then echo "Tables COUNT: ${TABLESCOUNT}"; fi
  if [ $TABLESCOUNT -eq 0 ]; then
	   if [ $DEBUG = "1" ]; then echo "SKIP: ${i}"; fi
	  continue
  fi
  ${MYSQL} -Be 'show table status' $i | cut -f 2 | grep InnoDB >/dev/null && \
    INNODBBASES="${INNODBBASES} $i" || \
    MYISAMBASES="${MYISAMBASES} $i"
done

for base in ${BASES}; do
  if [ ! -d ${BASEDIR}/${base} ]; then
    mkdir -p -m 750 ${BASEDIR}/${base}
  fi
done

if [ $DEBUG = "1" ]; then echo "Backup MyISAM bases: ${MYISAMBASES}"; fi
if [ $DEBUG = "1" ]; then echo "Backup InnoDB bases: ${INNODBBASES}"; fi
cd ${TMPDIR}
chown -R ${OWNER} .

mysql_check_repltable() {
	REPLTABLE_COUNT=`${MYSQL} -e 'show tables\g' mysql | grep ${REPL_TABLE}${base} | wc -l`
	if [ $REPLTABLE_COUNT -eq 0 ]; then 
	{
	    if [ $DEBUG = "1" ]; then
		echo "Creating ${REPL_TABLE}${base} for base: ${base}";
	    fi
		${MYSQL} -e "create table ${REPL_TABLE}${base} (host varchar(60) NOT null,time_stamp timestamp(14) NOT NULL, log_file  varchar(32) default NULL,log_pos int(11)     default NULL,master_host varchar(60) NULL,master_log_file varchar(32) NULL,master_log_pos int NULL,PRIMARY KEY (host))" mysql;
	} else {
	    if [ $DEBUG = "1" ]; then
		echo "Repl table ${REPL_TABLE}${base} for base: ${base} already exist";
	    fi
	}
	fi
}

if [ -z $REPLICATION ]; then {
     if [ $DEBUG = "1" ]; then
	echo "Doing backup WITHOUT replication"
     fi

	for base in ${MYISAMBASES}; do
		${MYSQLHOTCOPY} -q --addtodest --noindices ${base} ${TMPDIR}

	if [ -d ${TMPDIR}/${base} ]; then
		nice -n 20 tar -czf ${BASEDIR}/${base}/${base}.${DATE}.tar.gz ./${base}
		rm -rf ${TMPDIR}/${base}
	fi
	done
}
else
{
     if [ $DEBUG = "1" ]; then
        echo "Doing backup WITH replication"
     fi
	if [ -z $ONSLAVE ]; then {
	   if [ $DEBUG = "1" ]; then
		echo "Doing backup WITH replication on MASTER"
	   fi
	        for base in ${MYISAMBASES}; do
			mysql_check_repltable;
	                ${MYSQLHOTCOPY} -q --addtodest --noindices  --record_log_pos=mysql.${REPL_TABLE}${base} ${base} ${TMPDIR}
		        if [ -d ${TMPDIR}/${base} ]; then
				nice -n 20 tar -czf ${BASEDIR}/${base}/${base}.${DATE}.tar.gz ./${base}
				rm -rf ${TMPDIR}/${base}
			fi
		done
        } 
	else
	{
	  if [ $DEBUG = "1" ]; then
                echo "Doing backup WITH replication on SLAVE"
	  fi
                for base in ${MYISAMBASES}; do
			mysql_check_repltable;
                        ${MYSQLHOTCOPY} -q --addtodest --noindices --on_slave --record_log_pos=mysql.${REPL_TABLE}${base} ${base} ${TMPDIR}
                        if [ -d ${TMPDIR}/${base} ]; then
                        	nice -n 20 tar -czf ${BASEDIR}/${base}/${base}.${DATE}.tar.gz ./${base}
                        	rm -rf ${TMPDIR}/${base}
			fi
                done
	
	}
	fi
}
fi
	
rm -rf ${TMPDIR}

# InnoDB databases backup
if [ -z $REPLICATION ]; then {
	for base in ${INNODBBASES}; do
		if ( ${MYSQLDUMP} --opt --single-transaction $base | gzip -9 -c >${BASEDIR}/${base}/${base}.${DATE}.sql.gz ) 2>&1 | grep .; then
    		echo "Error backuping db: $base"
  		fi
	done
}
else
{
        if [ -z $ONSLAVE ]; then {
	   if [ $DEBUG = "1" ]; then
                echo "Doing backup WITH replication on MASTER"
	   fi
        	for base in ${INNODBBASES}; do
        		if ( ${MYSQLDUMP} --master-data=2 --opt --single-transaction $base | gzip -9 -c >${BASEDIR}/${base}/${base}.${DATE}.sql.gz ) 2>&1 | grep .; then
               		echo "Error backuping db: $base"
                	fi
		done
	}
	else
	{
	   if [ $DEBUG = "1" ]; then
		echo "Can't do backup on SLAVE InnoDB bases"
	   fi
	}
	fi
}
fi
