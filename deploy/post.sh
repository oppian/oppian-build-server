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

# save github known hosts
cat >> ~/.ssh/known_hosts <<EOF
|1|CxwX6zdE5cY2hjnnMMgT7J6fqPU=|oaWAkQid2ysupoipdrACc6XZABw= ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
|1|C2hLILCuBfn30RTd2vq+lD30Ixo=|7D8bRYoVxZ76vsgNO6IYMGqrN1Q= ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
EOF

# start the daemons
for botdir in master-oserver slave-localhost ; do
  buildbot start $botdir
done

# start the github callback
python github_buildbot.py &

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

chown -R www-data $DEPLOY_DIR
/etc/init.d/apache2 restart

