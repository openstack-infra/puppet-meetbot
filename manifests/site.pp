define meetbot::site(
  $channels,
  $network,
  $nick,
  $nickpass,
  $server,
  $use_ssl,
  $vhost_name = $::fqdn,
  $vhost_extra = undef,
  $manage_index = true,
) {

  $varlib = "/var/lib/meetbot/${name}"
  $meetbot = "/srv/meetbot-${name}"

  # NOTE(pabelanger): Until we full remove puppetlabs-apache from
  # system-config, we need to do this hack to avoid a circular dependency.
  if ! defined(Class['::apache']) {
    ::httpd::vhost { $vhost_name:
      port     => 80,
      docroot  => "/srv/meetbot-${name}",
      priority => '50',
      template => 'meetbot/vhost.erb',
    }
  } else {
    ::apache::vhost { $vhost_name:
      port     => 80,
      docroot  => "/srv/meetbot-${name}",
      priority => '50',
      template => 'meetbot/vhost.erb',
    }
  }

  file { $varlib:
    ensure  => directory,
    owner   => 'meetbot',
    require => File['/var/lib/meetbot'],
  }

  file { $meetbot:
    ensure => directory,
  }

  if manage_index == true {
    file { "${meetbot}/index.html":
      ensure  => present,
      content => template('meetbot/index.html.erb'),
      require => File[$meetbot],
    }
  }

  file { "${meetbot}/irclogs":
    ensure  => link,
    target  => "${varlib}/logs/ChannelLogger/${network}",
    require => File[$meetbot],
  }

  file { "${meetbot}/meetings":
    ensure  => link,
    target  => "${varlib}/meetings",
    require => File[$meetbot],
  }

  file { [
    "${varlib}/conf",
    "${varlib}/data",
    "${varlib}/backup",
    "${varlib}/logs"
  ]:
    ensure  => directory,
    owner   => 'meetbot',
    require => File[$varlib],
  }

  file { "${varlib}/data/tmp":
    ensure  => directory,
    owner   => 'meetbot',
    require => File["${varlib}/data"],
  }

  # set to root/root so meetbot doesn't overwrite
  file { "${varlib}.conf":
    ensure  => present,
    content => template('meetbot/supybot.conf.erb'),
    group   => 'root',
    notify  => Service["${name}-meetbot"],
    owner   => 'root',
    require => File['/var/lib/meetbot'],
  }

  file { "${varlib}/ircmeeting":
    ensure  => directory,
    owner   => 'meetbot',
    recurse => true,
    require => [
      Vcsrepo['/opt/meetbot'],
      File[$varlib]
    ],
    source  => '/opt/meetbot/ircmeeting',
  }

  file { "${varlib}/ircmeeting/meetingLocalConfig.py":
    ensure  => present,
    content => template('meetbot/meetingLocalConfig.py.erb'),
    notify  => Service["${name}-meetbot"],
    owner   => 'meetbot',
    require => File["${varlib}/ircmeeting"],
  }

  cron { 'irclog2html':
    user        => 'meetbot',
    weekday     => '*',
    hour        => '*',
    minute      => '*/15',
    command     => "find ${varlib}/logs/ChannelLogger/${network} -mindepth 1 -maxdepth 1 -type d | xargs -n1 logs2html",
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
  }

# we set this file as root ownership because meetbot overwrites it on shutdown
# this means when puppet changes it and restarts meetbot the file is reset
  file { "/etc/init/${name}-meetbot.conf":
    ensure  => present,
    content => template('meetbot/upstart.erb'),
    notify  => Service["${name}-meetbot"],
    owner   => 'root',
    replace => true,
    require => File["${varlib}.conf"],
  }

  service { "${name}-meetbot":
    provider  => upstart,
    require   => [
      Vcsrepo['/opt/meetbot'],
      File["/etc/init/${name}-meetbot.conf"]
    ],
    subscribe => [
      File['/usr/share/pyshared/supybot/plugins/MeetBot'],
      File["${varlib}/ircmeeting"]
    ],
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
