#!/bin/sh

DBDIR="db"
SNAPFILE="/www/.snap/1"
MNTDIR="/mnt"
BACKUPDIR="/www/backup"
DATE=`date +%Y%m%d`
DEBUG="1"
KEEPDAYS=23

find -L $BACKUPDIR -type f -name 'db_*.tar.gz' -mtime +$KEEPDAYS | xargs rm -f

D() {
	[ $DEBUG -eq 1 ] && echo $1
}
[ -f $SNAPFILE ] && echo "Snapfile $SNAPFILE exists, exiting..." && exit 255
[ -b /dev/md0 ] && echo "Memory device /dev/md0 exist, exiting..." && exit 255

D "Stopping MySQL:"
#/usr/local/etc/rc.d/mysql-server stop > /dev/null 2>&1
/usr/local/etc/rc.d/mysql-server stop > /dev/null 2>&1
D "Creating snapshot:"
mksnap_ffs $SNAPFILE
D "Creating memory device /dev/md0 and mounting it into $MNTDIR:"
mdconfig -a -t vnode -o readonly -f $SNAPFILE
mount -o ro /dev/md0 /mnt/
D "Starting MySQL:"
/usr/local/etc/rc.d/mysql-server start > /dev/null 2>&1
D "Creating tar.gz archive $BACKUPDIR/db_$DATE.tar.gz:"
tar czf $BACKUPDIR/db_$DATE.tar.gz $MNTDIR/$DBDIR
D "Unmoniting, removing device and snapshot:"

sync
umount -f $MNTDIR
sync
mdconfig -d -u /dev/md0
sync
rm -f $SNAPFILE
sync

D "OK"
exit 0
