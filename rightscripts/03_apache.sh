#!/bin/bash -e
#
# Installs apache and some apache modules and disables the default site
#
#

# Packages 	apache2-mpm-prefork libapache2-mod-macro libapache2-mod-python libapache2-mod-wsgi
# Inputs	-none-


#
# Test for a reboot,  if this is a reboot just skip this script.
#
if test "$RS_REBOOT" = "true" ; then
  echo "Skip code install on reboot."
  logger -t RightScale "Skip install on reboot."
  exit 0 # Leave with a smile ...
fi

a2dissite default