#!/bin/sh

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

export RAIDFLAG="/var/tmp/raidflag.$1"
MAILTO='root@example.ru'
CMD="/root/bin/cli32 ctrl=$1 vsf info"

#alias mail=echo

$CMD | perl -x $0

if ([ "$?" -gt "0" ];) then
	if (perl -e 'exit (-f $ENV{RAIDFLAG} and -M $ENV{RAIDFLAG} < 1/24)';) then
		$CMD | mail -E -s "`hostname` RAID channel $1 alert" $MAILTO;
		touch $RAIDFLAG;
	fi
else
	[ -e $RAIDFLAG ] && $CMD | mail -E -s "`hostname` RAID channel $1 recovery" $MAILTO;
	rm -f $RAIDFLAG 2>/dev/null
fi

exit

#!/usr/bin/perl

# raidutil output parser
# exit nonzero if any of the arrays id not optimal

$ret = 0;

while (<STDIN>) {
	$ret++ if (/Raid\d\s+[0-9\.]+GB\s+[0-9\/]+\s+(\S+)\s+$/ and $1 ne 'Normal');
}

exit $ret;
