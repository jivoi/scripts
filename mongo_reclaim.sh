#!/bin/bash

# Force MongoDB to only use as much storage as it needs
# instead of taking up more and more space without reclaiming it

# Make sure of the following:
#
# 1. The mongod user has its shell set to /bin/bash on both machines
# 2. The mongod user has SSH keys set up such that it can SSH from 
#    the primary to the secondary without prompt
# 3. The mongod user has the following permissions in /etc/sudoers:
#    mongod ALL=NOPASSWD: /sbin/service mongod status, /sbin/service mongod stop, /sbin/service mongod start
#    (modify accordingly if not using Red Hat/CentOS)
# 4. Make sure the requiretty option is off in /etc/sudoers

# Only run as mongod user
if [ "$(whoami)" != "mongod" ] ; then echo "Not mongod user" ; exit 1 ; fi

# Determine environment - change these as needed
case "$(hostname)" in
  primary.production.mydomain.com ) primary=primary.production.mydomain.com ; secondary=secondary.production.mydomain.com ;;
  primary.staging.mydomain.com ) primary=primary.staging.mydomain.com ; secondary=secondary.staging.mydomain.com ;;
  primary.development.mydomain.com ) primary=primary.development.mydomain.com ; secondary=secondary.development.mydomain.com ;;
  * ) echo "Unknown environment" ; exit 1 ;;
esac

# Check sudo and SSH
if ! sudo -n /sbin/service mongod status > /dev/null ; then
  echo "Problem with sudo on $primary" ; exit 1
elif ! ssh -q $secondary "sudo -n /sbin/service mongod status > /dev/null" ; then
  echo "Problem with SSH and/or sudo on $secondary" ; exit 1
fi

# Take backup on primary
echo -n "$(date +'%Y-%m-%d %H-%M-%S') Taking backup /tmp/dump on $primary..."
cd /tmp ; rm -rf dump ; mongodump > /dev/null
if [ "$?" != "0" ] ; then echo " Problem taking backup on $primary" ; exit 1 ; fi
echo " done"

# Clear data on secondary
echo -n "$(date +'%Y-%m-%d %H-%M-%S') Clearing data on $secondary..."
ssh -q $secondary "sudo -n /sbin/service mongod stop > /dev/null"
if [ "$?" != "0" ] ; then echo " Problem stopping mongod on $secondary" ; exit 1 ; fi
ssh -q $secondary "rm -rf /var/lib/mongo/*"
ssh -q $secondary "sudo -n /sbin/service mongod start > /dev/null"
if [ "$?" != "0" ] ; then echo " Problem starting mongod on $secondary" ; exit 1 ; fi
echo " done"

# Wait for secondary to come back up
issecondary=$(ssh -q $secondary "echo 'db.isMaster()' | mongo" | grep secondary | awk -F '[ ,]' '{print $3}')
echo -n "$(date +'%Y-%m-%d %H-%M-%S') Waiting for $secondary to come up..."
until [ "$issecondary" == "true" ] ; do
  sleep 5
  echo -n "."
  issecondary=$(ssh -q $secondary "echo 'db.isMaster()' | mongo" | grep secondary | awk -F '[ ,]' '{print $3}')
done
echo " done"

# Demote primary so secondary is master
echo -n "$(date +'%Y-%m-%d %H-%M-%S') Demoting $primary..."
echo 'rs.stepDown()' | mongo --quiet > /dev/null
if [ "$?" != "0" ] ; then echo " Problem demoting $primary" ; exit 1 ; fi
echo " done"

# Wait for secondary to take over as master
issecondary=$(echo 'db.isMaster()' | mongo | grep secondary | awk -F '[ ,]' '{print $3}')
echo -n "$(date +'%Y-%m-%d %H-%M-%S') Waiting for $secondary to become master..."
until [ "$issecondary" == "true" ] ; do
  sleep 5
  echo -n "."
  issecondary=$(echo 'db.isMaster()' | mongo | grep secondary | awk -F '[ ,]' '{print $3}')
done
echo " done"

# Clear data on primary
echo -n "$(date +'%Y-%m-%d %H-%M-%S') Clearing data on $primary..."
sudo -n /sbin/service mongod stop > /dev/null
if [ "$?" != "0" ] ; then echo " Problem stopping mongod on $primary" ; exit 1 ; fi
rm -rf /var/lib/mongo/*
sudo -n /sbin/service mongod start > /dev/null
if [ "$?" != "0" ] ; then echo " Problem starting mongod on $primary" ; exit 1 ; fi
echo " done"

# Wait for primary to come up
issecondary=$(echo 'db.isMaster()' | mongo | grep secondary | awk -F '[ ,]' '{print $3}')
echo -n "$(date +'%Y-%m-%d %H-%M-%S') Waiting for $primary to come up..."
until [ "$issecondary" == "true" ] ; do
  sleep 5
  echo -n "."
  issecondary=$(echo 'db.isMaster()' | mongo | grep secondary | awk -F '[ ,]' '{print $3}')
done
echo " done"

# Demote secondary so primary is master
echo -n "$(date +'%Y-%m-%d %H-%M-%S') Demoting $secondary..."
ssh -q $secondary "echo 'rs.stepDown()' | mongo --quiet > /dev/null"
if [ "$?" != "0" ] ; then echo " Problem demoting $secondary" ; exit 1 ; fi
echo " done"

# Wait for primary to take over as master
isprimary=$(echo 'db.isMaster()' | mongo | grep ismaster | awk -F '[ ,]' '{print $3}')
echo -n "$(date +'%Y-%m-%d %H-%M-%S') Waiting for $primary to become master..."
until [ "$isprimary" == "true" ] ; do
  sleep 5
  echo -n "."
  isprimary=$(echo 'db.isMaster()' | mongo | grep ismaster | awk -F '[ ,]' '{print $3}')
done
echo " done"
