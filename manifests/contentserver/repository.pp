# == Define: contentserver
#
# Adds an Apache configuration file.
# http://stackoverflow.com/questions/19024134/calling-puppet-defined-resource-with-multiple-parameters-multiple-times
#
class documentum::contentserver::repository(
  $ensure,
  $documentum,
  $version,
  $installer,
  $docbroker_port,
  $docbroker_name,
  $docbroker_host,
  $documentum_data,
  $repository_name,
  $repository_id,
  $repository_service,
  $repository_desc,
  $bof_registry_password,
  $db_user,
  $db_password,
  $db_connection,
  $db_tablespace,
  $service_name
  ) {


  # template(<FILE REFERENCE>, [<ADDITIONAL FILES>, ...])
  file { 'repository-response':
    ensure    => file,
    path      => '/home/dmadmin/sig/repository/repository.properties',
    owner     => dmadmin,
    group     => dmadmin,
    content   => template('documentum/repository.properties.erb'),
  }
  file { 'repository-data-dir':
    ensure    => directory,
    path      => $documentum_data,
    owner     => dmadmin,
    group     => dmadmin,
  }

  exec { "repository-create":
    command     => "${installer}/dm_launch_server_config_program.sh -f /home/dmadmin/sig/repository/repository.properties -r /home/dmadmin/sig/repository/response.properties -i Silent",
    cwd         => $installer,
    require     => [File["repository-response"],
                    File["repository-data-dir"],
                    Group["dmadmin"],
                    User["dmadmin"],
                    File["tnsnames"],
                    Exec["clientInstall"]],
    environment => ["HOME=/home/dmadmin",
                    "DOCUMENTUM=${documentum}",
                    "DOCUMENTUM_SHARED=${documentum}/shared",
                    "DM_HOME=${documentum}/product/${version}",
                    "ORACLE_HOME=/u01/app/oracle/product/12.1/client",
                    "ORACLE_SID=orcl",
                    ],
    creates     => "${documentum}/dba/dm_start_${repository_name}",
    user        => dmadmin,
    group       => dmadmin,
    logoutput   => true,
    timeout     => 3000,
    notify      => [File["dfc.properties"], Exec [ "r-install.log"], Exec [ "r-dmadmin.ServerConfigurator.log"]]
  }

  exec { "r-install.log":
    command     => "/bin/cat ${installer}/logs/install.log",
    cwd         => $installer,
    logoutput   => true,
  }
  exec { "r-dmadmin.ServerConfigurator.log":
    command     => "/bin/cat ${installer}/dmadmin.ServerConfigurator.log",
    cwd         => $installer,
    logoutput   => true,
  }

  file { 'dfc.properties':
    ensure    => file,
    path      => '/vagrant/repositorydata/dfc.properties',
    owner     => dmadmin,
    group     => dmadmin,
    source    => '/u01/app/documentum/shared/config/dfc.properties',
  }

# coppying the service file across
  file { 'repository-init.d':
    ensure    => file,
    path      => "/etc/init.d/${repository_service}",
    owner     => root,
    group     => root,
    mode      => 755,
    content   => template('documentum/services/docbase.erb'),
  }

  exec {'repository-docbroker':
    require     => [File["repository-init.d"],
                    Exec["repository-create"],
                  ],
    command  => "/sbin/chkconfig --add ${repository_service}; /sbin/chkconfig ${repository_service} on",
    #onlyif   => ["! /sbin/service ${jms_service} status"],
  }
}
