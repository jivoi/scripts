#!/bin/sh
. /usr/local/etc/svnconfbackup.conf

#Repo path in URL format
SVNROOTsvn="file://$SVNROOT"

which pax > /dev/null

if [ $? -ne 0 ] ; then 
  echo "Error: pax not found, aborting!"
  exit 1
fi

case "$1" in
init)
	 cd $TMPDIR
	 #Temporary directory creation
	 mkdir $DESTDIR
	 chmod 700 $DESTDIR
	 #Initial repository layout setup
	 mkdir $DESTDIR/branch
	 mkdir $DESTDIR/tag
	 mkdir $DESTDIR/trunk
	 cd $DESTDIR
	 #Check SVN root existence
	 if [ ! -d $SVNROOT ]; then
	   $SVNADMIN create $SVNROOT
	 fi
	 #Import repository tree
	 $SVN import $SVNROOTsvn/$REPDIR -q -m "Initial repository layout"
	 #Cleanup
	 cd ../
	 rm -rf $DESTDIR
	;;
update)
	 cd $TMPDIR
	 #Temporary directory creation
	 mkdir $DESTDIR
	 chmod 700 $DESTDIR
	 #svn working dir setup
	 $SVN checkout -q $SVNROOTsvn/$REPDIR/trunk $DESTDIR
	 cd $DESTDIR
	 #Build file list
	 list=`eval find $LIST $EXCLUDE_LIST -and -type f|sort`
	 #Copy files
	 for p in ${list} $FILES ; do
	  pax -rw $p . > /dev/null 2>&1
	 done;
	 #Build recently added files list
	 list=`eval $SVN status|grep ^?|awk '{print $2}'`
	 #Add these files to version control
	 for p in ${list} ; do
	  $SVN add -q $p
	 done;
	 #Build all files list except .svn dirs
	 list=`eval find . -name .svn -prune -or -print`
	 #Remove non-existent files from version control
	 for p in ${list} ; do
	  if [ ! -e /$p ]; then
	   $SVN delete -q $p --force
	  fi
	 done;
	 #Commit changes
	 $SVN diff
	 $SVN commit -q -m "svnbackup automatic update"
	 #Cleanup
	 cd ../
	 rm -rf $DESTDIR
esac
