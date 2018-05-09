include apache
include apache::mod::headers

include meetbot
$vhost_extra = '
  <Location /alert>
    Header set Access-Control-Allow-Origin "*"
  </Location>
'
meetbot::site { 'openstack':
  nick         => 'openstack',
  nickpass     => 'nickpass',
  network      => 'FreeNode',
  server       => 'chat.freenode.net:7000',
  use_ssl      => 'True',
  vhost_extra  => $vhost_extra,
  vhost_name   => 'eavesdrop.openstack.org',
  manage_index => true,
  channels     => ['#one', '#two', '#three'],
}
