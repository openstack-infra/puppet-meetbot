# Class: meetbot::params
#
class meetbot::params {
  $plugins_dir = $::lsbdistcodename ? {
    'xenial' => '/usr/lib/python2.7/dist-packages',
    default  => '/usr/share/pyshared',
  }
  $initd = $::lsbdistcodename ? {
    'trusty' => 'upstart',
    default  => 'systemd',
  }
}
