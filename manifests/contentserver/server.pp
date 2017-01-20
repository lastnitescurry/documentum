# == Define: contentserver
#
# Adds an Apache configuration file.
# http://stackoverflow.com/questions/19024134/calling-puppet-defined-resource-with-multiple-parameters-multiple-times
#
class documentum::contentserver::server() {

$installer   = '/home/dmadmin/sig/cs'
$documentum  = '/u01/app/documentum'
$port        = '9080'
$version     = '7.3'
$jms_service = 'jms'
$oracle_home = '/u01/app/oracle/product/12.1/client'

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
   #onlyif   => ["! /sbin/service ${jms_service} status"],
 }

## now we actually install the software
  exec { "cs-installer":
   command   => "/bin/tar xvf /opt/media/Repository/7.3/Content_Server_7.3_linux64_oracle.tar",
   require   => Service["rngd"],
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
   timeout     => 1800,
   logoutput   => true,
 }

## copy files across that will be necessary for DCTM services
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
    owner     => dmadmin,
    group     => dmadmin,
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
