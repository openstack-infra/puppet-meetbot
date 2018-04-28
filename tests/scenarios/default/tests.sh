#!/usr/bin/env bash

set -eux

test_site_is_alive() {
    curl http://localhost | grep 'Welcome to Openstack IRC log server' || return 1
    return 0
}

test_vhost_content() {
    expected_vhost=$(mktemp)
    cat <<EOF > $expected_vhost
# ************************************
# Managed by Puppet
# ************************************

NameVirtualHost *:80
<VirtualHost *:80>
  ServerName eavesdrop.openstack.org
  DocumentRoot /srv/meetbot-openstack
  <FilesMatch \.log$>
    ForceType text/plain
    AddDefaultCharset UTF-8
  </FilesMatch>
  <Directory /srv/meetbot-openstack>
    Options Indexes FollowSymLinks MultiViews
    AllowOverride None
    Order allow,deny
    allow from all
    <IfVersion >= 2.4>
      Require all granted
    </IfVersion>
  </Directory>


  <Location /alert>
    Header set Access-Control-Allow-Origin "*"
  </Location>


  ErrorLog /var/log/apache2/eavesdrop.openstack.org_error.log
  LogLevel warn
  CustomLog /var/log/apache2/eavesdrop.openstack.org_access.log combined
  ServerSignature Off
</VirtualHost>
EOF
    diff $expected_vhost /etc/apache2/sites-enabled/50-eavesdrop.openstack.org.conf || return 1
    return 0
}

declare -a tests
tests=(
    test_site_is_alive
    test_vhost_content
)
for test in ${tests[@]} ; do
    $test || exit 1
done

exit 0
