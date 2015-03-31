#!/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

export RAIDFLAG="/var/tmp/raidflag"
MAILTO='root@example.ru'
CMD="/sbin/mdadm -D /dev/md0 /dev/md1 /dev/md2 /dev/md3 /dev/md4 /dev/md5 /dev/md6"

#alias mail=echo

$CMD | grep degraded > /dev/null 2>&1

if ([ "$?" -ne "1" ];) then
	if (perl -e 'exit (-f $ENV{RAIDFLAG} and -M $ENV{RAIDFLAG} < 1/24)';) then
		$CMD | mail -s "`hostname` RAID alert" $MAILTO;
		touch $RAIDFLAG;
	fi
else
	[ -e $RAIDFLAG ] && $CMD | mail -s "`hostname` RAID recovery" $MAILTO;
	rm -f $RAIDFLAG 2>/dev/null
fi

exit
