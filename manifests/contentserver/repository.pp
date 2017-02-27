# == Define: contentserver
#
# Adds an Apache configuration file.
# http://stackoverflow.com/questions/19024134/calling-puppet-defined-resource-with-multiple-parameters-multiple-times
#
define documentum::contentserver::repository(
  $installer_location,
  $documentum,
  $dctm_owner,
  $dctm_group,
  $version,

  $docbroker_port,
  $docbroker_name,
  $docbroker_host,

  $repository_name = $name,
  $repository_id,
  $repository_service,
  $repository_desc,
  $repository_host,
  $repository_data_dir,
  $db_user,
  $db_password,
  $db_connection,
  $db_tablespace,
  $oracle_home,
  $bof_registry_password,

  $installer      = "${documentum}/product/${version}/install",
  ) {

  # template(<FILE REFERENCE>, [<ADDITIONAL FILES>, ...])
  file { 'repository-response':
    ensure    => file,
    path      => "${installer_location}/repository/repository.properties",
    owner     => $dctm_owner,
    group     => $dctm_group,
    content   => template('documentum/contentserver/repository.properties.erb'),
  }
  file { 'repository-data-dir':
    ensure    => directory,
    path      => $repository_data_dir,
    owner     => $dctm_owner,
    group     => $dctm_group,
  }

  exec { "repository-create":
    command     => "${installer}/dm_launch_server_config_program.sh -f ${installer_location}/repository/repository.properties -r ${installer_location}/repository/response.properties -i Silent",
    cwd         => $installer,
    require     => [File["repository-response"],
                    File["repository-data-dir"],
                    User["${dctm_owner}"],
                    File["tnsnames"],
                    Exec["clientInstall"]],
    environment => ["HOME=/home/${dctm_owner}",
                    "DOCUMENTUM=${documentum}",
                    "DOCUMENTUM_SHARED=${documentum}/shared",
                    "DM_HOME=${documentum}/product/${version}",
                    "ORACLE_HOME=${oracle_home}",
                    "ORACLE_SID=${db_connection}",
                    ],
    creates     => "${documentum}/dba/dm_start_${repository_name}",
    user        => $dctm_owner,
    group       => $dctm_group,
    logoutput   => true,
    timeout     => 3000,
  }

# coppying the service file across
  file { 'repository-service':
    ensure    => file,
    path      => "/usr/lib/systemd/system/${repository_name}.service",
    owner     => root,
    group     => root,
    mode      => 755,
    content   => template('documentum/contentserver/repository.service.erb'),
  }
  exec {'repository-docbroker':
    require     => [File["repository-service"],
                  ],
    command  => "/bin/systemctl --system daemon-reload",
    }
}
