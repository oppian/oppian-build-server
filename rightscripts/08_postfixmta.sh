#!/bin/bash -ex
#
# Installs postfix with a relay to google apps
#
#

# Packages 	postfix mailx
# Inputs	DOMAIN, GOOGLE_PASSWD, GOOGLE_USER, HOSTNAME

#
# Test for a reboot,  if this is a reboot just skip this script.
#
if test "$RS_REBOOT" = "true" ; then
  echo "Skip code install on reboot."
  logger -t RightScale "Skip install on reboot."
  exit 0 # Leave with a smile ...
fi

cat > /etc/postfix/main.cf <<EOF
myhostname = $HOSTNAME
mydomain = $DOMAIN
myorigin = \$mydomain

smtpd_banner = \$myhostname ESMTP \$mail_name
biff = no
append_dot_mydomain = no

alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
mydestination = localdomain, localhost, localhost.localdomain, localhost
mynetworks = 127.0.0.0/8
mailbox_size_limit = 0
recipient_delimiter = +

# SECURITY NOTE: Listening on all interfaces. Make sure your firewall is
# configured correctly
inet_interfaces = all

relayhost = [smtp.gmail.com]
smtp_connection_cache_destinations = smtp.gmail.com
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = static:$GOOGLE_USER:$GOOGLE_PASSWD
smtp_sasl_security_options = noanonymous
smtp_tls_security_level = may

default_destination_concurrency_limit = 4

soft_bounce = yes
EOF

newaliases

/etc/init.d/postfix restart