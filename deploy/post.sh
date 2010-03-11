#!/bin/bash -xe

# This is called post download and used to setup the environment for the first time.

# argument will be deploy dir
DEPLOY_DIR=$1
HOSTNAME=build.oppian.com

# kill off any other buildbots
(pgrep -f buildbot)
(pkill -9 -f buildbot)

# create the virtual env
python boot.py build-env

# activate it
source build-env/bin/activate

# install requirements
pip install -r requirements.txt

# copy ssh key and set mode
cp deploy/id_rsa ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

# start the daemons
for botdir in master-oserver slave-localhost ; do
  buildbot start $botdir
done

# apache

# enable mod_proxy
a2enmod proxy
a2enmod proxy_http

# rewrite template
sed -e "s|@DEPLOY_DIR@|$DEPLOY_DIR|g" -e "s|@HOSTNAME@|$HOSTNAME|g" $DEPLOY_DIR/apache/http.conf.template > $DEPLOY_DIR/apache/http.conf

echo "Linking to apache config..."
ln -s -f $DEPLOY_DIR/apache/http.conf /etc/apache2/sites-available/build
a2ensite build

echo "Restarting apache..."
apache2ctl configtest
apache2ctl restart
