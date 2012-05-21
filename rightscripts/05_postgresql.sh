#!/bin/bash -e
#
# Installs and configures PostgreSQL
#

# Packages 	postgresql postgresql-client postgresql-contrib python-psycopg2
# Inputs	DB_ADMIN_PASS, PGDATA


#
# Test for a reboot,  if this is a reboot just skip this script.
#
if test "$RS_REBOOT" = "true" ; then
  echo "Skip code install on reboot."
  logger -t RightScale "Skip install on reboot."
  /etc/init.d/postgresql-8.3 restart
  exit 0 # Leave with a smile ...
fi

/etc/init.d/postgresql-8.3 stop

## set data_directory
sed -i "s|/var/lib/postgresql/8.3/main|$PGDATA|" /etc/postgresql/8.3/main/postgresql.conf

## turn off ssl
sed -i 's|^ssl =|# ssl =|' /etc/postgresql/8.3/main/postgresql.conf

## if datadir doesn't exist
if [ ! -e $PGDATA ] ; then 

  ## create data dir and init
  mkdir $PGDATA
  chown postgres $PGDATA
  
  ## copy the old dir
  rsync -avz /var/lib/postgresql/8.3/main/ $PGDATA

  ## startup again
  /etc/init.d/postgresql-8.3 start

  ## reset postgres admin account
  sudo -u postgres psql postgres <<EOF
ALTER USER postgres WITH PASSWORD '$DB_ADMIN_PASS';
EOF


fi

/etc/init.d/postgresql-8.3 restart