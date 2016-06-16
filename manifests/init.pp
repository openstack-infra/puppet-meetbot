class meetbot {
    include ::httpd

  # The Apache mod_version module only needs to be enabled on Ubuntu 12.04
  # as it comes compiled and enabled by default on newer OS, including CentOS
  if !defined(Httpd::Mod['version']) and $::operatingsystem == 'Ubuntu' and $::operatingsystemrelease == '12.04' {
    httpd::mod { 'version':
      ensure => present
    }
  }

  vcsrepo { '/opt/meetbot':
    ensure   => latest,
    provider => git,
    source   => 'https://git.openstack.org/openstack-infra/meetbot',
  }

  vcsrepo { '/opt/ubuntu_supybot_plugins':
    ensure   => present,
    provider => bzr,
    require  => [
      Package['bzr'],
    ],
    source   => 'lp:ubuntu-bots'
  }

  user { 'meetbot':
    gid     => 'meetbot',
    home    => '/var/lib/meetbot',
    shell   => '/usr/sbin/nologin',
    system  => true,
    require => Group['meetbot'],
  }

  group { 'meetbot':
    ensure => present,
  }

  $packages = [
    'supybot',
    'bzr',
    'python-launchpadlib',
    'python-soappy',
    'python-twisted'
  ]

  package { $packages:
    ensure => present,
  }

  package { 'irclog2html':
    ensure   => 'present',
    provider => openstack_pip,
  }

  file { '/var/lib/meetbot':
    ensure  => directory,
    owner   => 'meetbot',
    require => User['meetbot'],
  }

  file { '/usr/share/pyshared/supybot/plugins/MeetBot':
    ensure  => directory,
    recurse => true,
    require => [
      Package['supybot'],
      Vcsrepo['/opt/meetbot']
    ],
    source  => '/opt/meetbot/MeetBot',
  }

  file { '/usr/share/pyshared/supybot/plugins/Bugtracker':
    ensure  => directory,
    recurse => true,
    require => [
      Package['supybot'],
      Vcsrepo['/opt/ubuntu_supybot_plugins']
    ],
    source  => '/opt/ubuntu_supybot_plugins/Bugtracker',
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
