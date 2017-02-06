# == Define: contentserver
#
# Adds an Apache configuration file.
# http://stackoverflow.com/questions/19024134/calling-puppet-defined-resource-with-multiple-parameters-multiple-times
#
define documentum::xplore::server(
   $installer_location,
   $source_location,
   $xplore_home,
   $version,
   $xplore_owner,
   $xplore_group,
  ) {

 file { 'rngd-properties':
   ensure  => file,
   path    => '/etc/sysconfig/rngd',
   owner   => root,
   group   => root,
   content => template('documentum/rngd.erb'),
 }

 service { 'rngd':
   ensure  => running,
   enable  => true,
 }

 file { 'server-properties':
   ensure    => file,
   path      => "${installer_location}/server/server.properties",
   owner     => $xplore_owner,
   group     => $xplore_group,
   content   => template('documentum/xplore/server.properties.erb'),
 }

  exec { "xplore-installer":
    command   => "/bin/tar xvf ${source_location}/Search/${version}/xPlore_${version}_linux-x64.tar",
    require   => Service["rngd"],
    cwd       => "${installer_location}/server",
    creates   => "${installer_location}/server/setup.bin",
    user      => $xplore_owner,
    group     => $xplore_group,
    logoutput => true,
  }

  exec { "xplore-install":
    command     => "${installer_location}/server/setup.bin -f ${installer_location}/server/server.properties",
    cwd         => "${installer_location}/server",
    require     => [Exec["xplore-installer"],
                    User["${xplore_owner}"],
                    Host["xplore.local"],
                    File["${xplore_home}"],],
    environment => ["HOME=/home/${xplore_owner}",
                    "XPLORE_HOME=${xplore_home}"],
    creates     => "${xplore_home}/installinfo/version.properties",
    user        => $xplore_owner,
    group       => $xplore_group,
    timeout     => 1800,
    logoutput   => true,
  }
}
