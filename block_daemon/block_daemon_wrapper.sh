#!/bin/sh
#Small wrapper for block_daemon.pl
if [ -f /tmp/block_daemon.pid ] ; then
   # the pid file already exists, so what to do?
   if [ "$(ps -aux|grep `cat /tmp/block_daemon.pid` |grep -v grep | wc -l)" -eq 1 ]; then
     # process is still running
     exit 0
   else
     # process not running, but pid file not deleted?
     rm /tmp/block_daemon.pid
     perl /root/bin/block_daemon.pl
   fi
fi

