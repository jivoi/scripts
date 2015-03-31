#!/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

export RAIDFLAG="/var/tmp/raidflag"
MAILTO="root@example.ru"

#alias mail=echo

NONOPT=`sysctl -n dev.mpt.1.nonoptimal_volumes`
# test if the oid exists at all
[ $? = 0 ] || exit 1

REPORTCMD="echo dmesg output follows; echo; dmesg | grep mpt | tail -n 20"

if ([ "$NONOPT" -gt "0" ];) then
        if (perl -e 'exit (-f $ENV{RAIDFLAG} and -M $ENV{RAIDFLAG} < 1/24)';) then
                eval $REPORTCMD | mail -s "`hostname` RAID alert" $MAILTO;
                touch $RAIDFLAG;
        fi
else
        [ -e $RAIDFLAG ] && eval $REPORTCMD | mail -s "`hostname` RAID recovery" $MAILTO;
        rm -f $RAIDFLAG 2>/dev/null
fi

exit

#!perl

# raidutil output parser
# exit nonzero if any of the arrays id not optimal

$ret = 0;

while (<STDIN>) {
        $ret++ if (/State:\s+(\S+)/ and $1 ne 'up');
}

exit $ret;
