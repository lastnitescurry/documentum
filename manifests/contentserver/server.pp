# == Define: contentserver
#
# Adds an Apache configuration file.
# http://stackoverflow.com/questions/19024134/calling-puppet-defined-resource-with-multiple-parameters-multiple-times
#
class documentum::contentserver::server() {
#  file { "cs-response-file":
#    path    => '/home/dmadmin/sig/cs/server.properties',
#    owner   => 'dmadmin',
#    group   => 'dmadmin',
#    mode    => '0644',
#    source  => 'puppet:///modules/documentum/server.properties',
#  }

 file { 'rngd-properties':
   ensure  => file,
   path    => '/etc/sysconfig/rndg',
   owner   => root,
   group   => root,
   content => template('documentum/rngd.erb'),
 }

 service { 'rngd':
   enable => true,
 }

  $installer  = '/home/dmadmin/sig/cs'
  $documentum = '/u01/app/documentum'
  $port       = '9080'
  $version    = '7.3'

  exec { "cs-installer":
    command   => "/bin/tar xvf /opt/media/Repository/7.3/Content_Server_7.3_linux64_oracle.tar",
    require   => Service["rndg"],
    cwd       => $installer,
    creates   => "${installer}/serverSetup.bin",
    user      => dmadmin,
    group     => dmadmin,
    logoutput => true,
  }

  exec { "cs-install":
    command     => "${installer}/serverSetup.bin -i Silent -DAPPSERVER.SERVER_HTTP_PORT=${port} -DAPPSERVER.SECURE.PASSWORD=dm_bof_registry",
    cwd         => $installer,
    require     => [Exec["cs-installer"],
                    Group["dmadmin"],
                    User["dmadmin"]],
    environment => ["HOME=/home/dmadmin",
                    "DOCUMENTUM=${documentum}",
                    "DOCUMENTUM_SHARED=${documentum}/shared",
                    "DM_HOME=${documentum}/product/${version}"],
#    creates     => "${installer}/response.cs.properties",
    creates     => "${documentum}/product/${version}/version.txt",
    user        => dmadmin,
    group       => dmadmin,
#    timeout     => 1800,
    logoutput   => true,
  }
}
