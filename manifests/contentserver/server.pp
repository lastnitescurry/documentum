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

 exec {'libsas':
   command  => "/bin/ln -s /usr/lib64/libsasl2.so.3.0.0 /usr/lib64/libsasl2.so.2",
  creates   => "/usr/lib64/libsasl2.so.2",
 }


## making the JMS a service
##TODO look at moving this out to another class
 file { 'jms-serviceStartScript':
   ensure    => file,
   path      => "/usr/lib/systemd/system/${jms_service}.service",
   owner     => root,
   group     => root,
   mode      => 755,
   content   => template('documentum/content/jms.service.erb'),
 }

 file { 'dctm-env':
   ensure    => file,
   path      => "/etc/default/dctm",
   owner     => root,
   group     => root,
   mode      => 755,
   content   => template('documentum/content/dctm.erb'),
 }

 exec {'chkconfig-jms':
   require     => [File["jms-serviceStartScript"],
                   File["dctm-env"],
                 ],
   command  => "systemctl --system daemon-reload",
   }

## now we actually install the software
  exec { "cs-installer":
   command   => "/bin/tar xvf ${source_location}/Repository/${version}/Content_Server_${version}_linux64_oracle.tar",
   require   => [Service["rngd"],
                File["${documentum}"]],
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
                   User["${dctm_owner}"],
                   Exec["libsas"]],
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
}
