define meetbot::site(
  $channels,
  $network,
  $nick,
  $nickpass,
  $server,
  $use_ssl,
  $vhost_extra  = undef,
  $vhost_name   = $::fqdn,
  $manage_index = true,
) {
  include ::meetbot::params

  $varlib = "/var/lib/meetbot/${name}"
  $meetbot = "/srv/meetbot-${name}"

  $port = 80
  $docroot = "/srv/meetbot-${name}"
  $srvname = $vhost_name
  $_vhost_name = '*'
  $options = 'Indexes FollowSymLinks MultiViews'
  ::httpd::vhost { $vhost_name:
    port     => 80,
    docroot  => "/srv/meetbot-${name}",
    priority => '50',
    content  => template('meetbot/vhost.erb'),
  }

  file { $varlib:
    ensure  => directory,
    owner   => 'meetbot',
    require => File['/var/lib/meetbot'],
  }

  file { $meetbot:
    ensure => directory,
  }

  if $manage_index == true {
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

  if ($::meetbot::params::initd == 'systemd') {
    $initd_path = "/etc/systemd/system/${name}-meetbot.service"
    # This is a hack to make sure that systemd is aware of the new service
    # before we attempt to start it.
    exec { "${name}-meetbot-systemd-daemon-reload":
      command     => '/bin/systemctl daemon-reload',
      before      => Service["${name}-meetbot"],
      subscribe   => File["${name}-initd"],
      refreshonly => true,
    }
  } else {
    $initd_path = "/etc/init/${name}-meetbot.conf"
  }

  file { "${name}-initd":
    ensure  => present,
    path    => $initd_path,
    content => template("meetbot/${::meetbot::params::initd}.erb"),
    notify  => Service["${name}-meetbot"],
    owner   => 'root',
    replace => true,
    require => File["${varlib}.conf"],
  }

  service { "${name}-meetbot":
    provider  => $::meetbot::params::initd,
    require   => [
      Vcsrepo['/opt/meetbot'],
      File["${name}-initd"]
    ],
    subscribe => [
      File["${::meetbot::params::plugins_dir}/supybot/plugins/MeetBot"],
      File["${varlib}/ircmeeting"]
    ],
    enable => true,
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
