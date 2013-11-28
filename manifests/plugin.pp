#
#
#
define jenkins::plugin(
  $version = 0,
  $http_base = 'http://updates.jenkins-ci.org',
) {
  $plugin            = "${name}.hpi"
  $plugin_dir        = '/var/lib/jenkins/plugins'
  $plugin_parent_dir = '/var/lib/jenkins'

  if ($version != 0) {
    $base_url = "${http_base}/download/plugins/${name}/${version}/"
  }
  else {
    $base_url = "${http_base}/latest/"
  }

  if (!defined(File[$plugin_dir])) {
    file {
      [$plugin_parent_dir, $plugin_dir]:
        ensure  => directory,
        owner   => 'jenkins',
        group   => 'jenkins',
        require => [Group['jenkins'], User['jenkins']];
    }
  }

  if (!defined(Group['jenkins'])) {
    group {
      'jenkins' :
        ensure  => present,
        require => Package['jenkins'];
    }
  }

  if (!defined(User['jenkins'])) {
    user {
      'jenkins' :
        ensure  => present,
        require => Package['jenkins'];
    }
  }

  if (!defined(Package['wget'])) {
    package {
      'wget' :
        ensure => present;
    }
  }

  exec {
    "download-${name}" :
      command    => "wget --no-check-certificate ${base_url}${plugin}",
      cwd        => $plugin_dir,
      require    => [File[$plugin_dir], Package['wget']],
      path       => ['/usr/bin', '/usr/sbin',],
      unless     => "test -f ${plugin_dir}/${name}.hpi || test -f ${plugin_dir}/${name}.jpi",
  }

  file {
    "${plugin_dir}/${plugin}" :
      require => Exec["download-${name}"],
      owner   => 'jenkins',
      mode    => '0644',
      notify  => Service['jenkins']
  }
}
