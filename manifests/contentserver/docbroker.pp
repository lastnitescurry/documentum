# == Define: contentserver
#
# Adds an Apache configuration file.
# http://stackoverflow.com/questions/19024134/calling-puppet-defined-resource-with-multiple-parameters-multiple-times
#
class documentum::contentserver::docbroker() {
  $ensure         = file
  $documentum     = '/u01/app/documentum'
  $version        = '7.3'
  $installer      = '/u01/app/documentum/product/7.3/install'
  $docbroker_port = 1489
  $docbroker_name = Docbroker
  $docbroker_host = $hostname

  # template(<FILE REFERENCE>, [<ADDITIONAL FILES>, ...])
  file { 'docbroker-response':
    ensure    => file,
    path      => '/home/dmadmin/sig/docbroker/docbroker.properties',
    owner     => dmadmin,
    group     => dmadmin,
    content   => template('documentum/docbroker.properties.erb'),
  }

  exec { "docbroker-create":
    command     => "${installer}/dm_launch_server_config_program.sh -f /home/dmadmin/sig/docbroker/docbroker.properties -r /home/dmadmin/sig/docbroker/response.properties -i Silent",
    cwd         => $installer,
    require     => [File["docbroker-response"],
                    Group["dmadmin"],
                    User["dmadmin"]],
    environment => ["HOME=/home/dmadmin",
                    "DOCUMENTUM=${documentum}",
                    "DOCUMENTUM_SHARED=${documentum}/shared",
                    "DM_HOME=${documentum}/product/${version}",
                    "ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe",
                    "ORACLE_SID=XE",
                    ],
    creates     => "${documentum}/dba/dm_launch_${docbroker_name}",
    user        => dmadmin,
    group       => dmadmin,
    logoutput   => true,
    timeout     => 3000,
    notify      => [Exec [ "b-install.log"], Exec [ "b-dmadmin.ServerConfigurator.log"]]
  }

  exec { "b-install.log":
    command     => "/bin/cat ${installer}/logs/install.log",
    cwd         => $installer,
    logoutput   => true,
  }
  exec { "b-dmadmin.ServerConfigurator.log":
    command     => "/bin/cat ${installer}/dmadmin.ServerConfigurator.log",
    cwd         => $installer,
    logoutput   => true,
  }


# coppying the service file across
  file { 'docbroker-init.d':
    ensure    => file,
    path      => '/etc/init.d/${docbroker_name}',
    owner     => root,
    group     => root,
    mode      => 755,
    content   => template('documentum/services/docbroker.erb'),
  }

  exec {'chkconfig-docbroker':
    require     => [File["docbroker-init.d"],
                    Exec["docbroker-create"],
                  ],
    command  => "/sbin/chkconfig --add ${docbroker_name}; /sbin/chkconfig ${docbroker_name} on",
    #onlyif   => ["! /sbin/service ${jms_service} status"],
  }
}
