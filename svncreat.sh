#!/bin/sh
#
# create svn repo $1 for group $2

SVNADMIN=/usr/bin/svnadmin
SVN=/usr/bin/svn

TMP_DIR=/tmp/svncreate/

usage () {
        echo "Usage: svncreate.sh PATH GROUP"
}

if [ -z "$1" -o -z "$2" ]; then
        usage; exit 0;
fi

if [ -e "$1" ]; then
        echo "ERROR: $1 exists";
        usage; exit 0;
fi

if ! egrep -qi "^$2:" /etc/group; then
        echo "ERROR: group $2 does not exist"
        usage; exit 0;
fi

$SVNADMIN create $1 --fs-type=fsfs

if [ ! -d "$1" ]; then
        echo "ERROR: could not create repository $1";
        usage; exit 0;
fi

chown -R :"$2" "$1"
chmod -R g+w "$1"
chmod -R o-rwx "$1"

#
mkdir -p ${TMP_DIR}.$$/branches ${TMP_DIR}.$$/tags ${TMP_DIR}.$$/trunk && \
${SVN} import -m "creating branches, tags, trunk.." ${TMP_DIR}.$$/ file://$1
rm -r ${TMP_DIR}.$$
#

