# == Define: contentserver
#
# Adds an Apache configuration file.
# http://stackoverflow.com/questions/19024134/calling-puppet-defined-resource-with-multiple-parameters-multiple-times
#
define documentum::contentserver::server(
  $installer_location,
  $source_location,
  $documentum,
  $dctm_owner,
  $version,
  $jms_port,
  $jms_service,
  $bof_registry_password,
  $oracle_home,
) {

## random number generator necessary for 7.3
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

## making the JMS a service
##TODO look at moving this out to another class
 file { 'jms-serviceConfig':
   ensure    => file,
   path      => "/etc/default/${jms_service}.conf",
   owner     => root,
   group     => root,
   mode      => 755,
   content   => template('documentum/services/service.conf.erb'),
 }
 file { 'jms-serviceStartScript':
   ensure    => file,
   path      => "/etc/init.d/${jms_service}",
   owner     => root,
   group     => root,
   mode      => 755,
   content   => template('documentum/services/service.erb'),
 }

 exec {'chkconfig-jms':
   require     => [File["jms-serviceConfig"],
                   File["jms-serviceStartScript"],
                 ],
   command  => "/sbin/chkconfig --add ${jms_service}; /sbin/chkconfig ${jms_service} on",
   onlyif    =>  "/usr/bin/test `/sbin/chkconfig --list | /bin/grep ${jms_service} | /usr/bin/wc -l` -eq 0",
 }

## now we actually install the software
  exec { "cs-installer":
   command   => "/bin/tar xvf ${source_location}/Repository/${version}/Content_Server_${version}_linux64_oracle.tar",
   require   => Service["rngd"],
   cwd       => $installer_location,
   creates   => "${installer_location}/serverSetup.bin",
   user      => $dctm_owner,
   group     => $dctm_group,
   logoutput => true,
}

 exec { "cs-install":
   command     => "${installer_location}/serverSetup.bin -i Silent -DAPPSERVER.SERVER_HTTP_PORT=${jms_port} -DAPPSERVER.SECURE.PASSWORD=${bof_registry_password}",
   cwd         => $installer_location,
   require     => [Exec["cs-installer"],
                   Host["dctm.local"],
                   User["${dctm_owner}"]],
   environment => ["HOME=/home/${dctm_owner}",
                   "DOCUMENTUM=${documentum}",
                   "DOCUMENTUM_SHARED=${documentum}/shared",
                   "DM_HOME=${documentum}/product/${version}"],
#    creates     => "${installer}/response.cs.properties",
   creates     => "${documentum}/product/${version}/version.txt",
   user        => $dctm_owner,
   group       => $dctm_group,
   timeout     => 1800,
   logoutput   => true,
 }

## copy files across that will be necessary for DCTM services

## TODO   move this somewhere else (possible)
  file { 'documentum.sh':
    ensure    => file,
    require   => [Exec["cs-install"]],
    path      => "/etc/profile.d/documentum.sh",
    owner     => root,
    group     => root,
    mode      => 755,
    content   => template('documentum/services/documentum.sh.erb'),
  }

  file { 'get_pid.sh':
    ensure    => file,
    require   => [Exec["cs-install"]],
    path      => "${documentum}/product/${version}/bin/get_pid",
    owner     => $dctm_owner,
    group     => $dctm_group,
    mode      => 755,
    content   => template('documentum/services/get_pid.erb'),
  }

  file { 'daemonize':
    ensure    => file,
    path      => "/usr/local/sbin/daemonize",
    owner     => root,
    group     => root,
    mode      => 755,
    source => 'puppet:///modules/documentum/daemonize';
  }

  file { 'daemonize.1':
    ensure    => file,
    path      => "/usr/local/share/man/man1/daemonize.1",
    owner     => root,
    group     => root,
    mode      => 644,
    source => 'puppet:///modules/documentum/daemonize.1';
  }
}
