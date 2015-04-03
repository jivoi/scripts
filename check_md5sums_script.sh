#!/bin/sh

OS=`uname`
if [ x$OS = xLinux ]; then
        export MD5=/usr/bin/md5sum
        DIRS="/bin /boot /lib /root /sbin /usr/bin /usr/games /usr/include /usr/kerberos /usr/lib /usr/libexec /usr/local/bin /usr/local/include /usr/local/lib /usr/local/sbin /usr/sbin"
        #DIRS="/bin"
        find $DIRS -type f | sort | awk '{print "$MD5 " $1 " | tr \"\n\" \" \"; ls -la " $1}' | sh | awk '{print $3 "\t" $2 "\t" $1}'
else
        export MD5=/sbin/md5
        DIRS="/bin /boot /lib /libexec /root /sbin /usr/bin /usr/games /usr/include /usr/lib* /usr/local/bin /usr/local/include /usr/local/lib /usr/local/libexec /usr/sbin /usr/local/sbin"
        #DIRS="/bin"
        find $DIRS -type f | sort | awk '{print "$MD5 " $1 " | tr \"\n\" \" \"; ls -la " $1}' | sh | awk '{print $5 "\t" $NF "\t" $4}'
fi