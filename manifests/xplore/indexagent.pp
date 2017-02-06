# == Define: indexagent
#
# Adds an Apache configuration file.
# http://stackoverflow.com/questions/19024134/calling-puppet-defined-resource-with-multiple-parameters-multiple-times
#
define documentum::xplore::indexagent(
  $installer_location,
  $xplore_home,
  $version,
  $xplore_owner,
  $xplore_group,

  $dsearch_host,
# note this should only be the first two ports, eg if 9300, use 93
  $dsearch_port,

  $ia_service_name,
  $ia_host,
  $ia_port,
  $ia_password,
  $ia_storage,

  $repository,
  $repository_user,
  $repository_password,
  $docbroker_host,
  $docbroker_port,
  $globalrepo,
  $globaluser,
  $globalpassword,

  $service_name    = $ia_service_name
  ) {
  # template(<FILE REFERENCE>, [<ADDITIONAL FILES>, ...])
  file { 'ia-response':
    ensure    => file,
    path      => "${installer_location}/ia/indexagent.properties",
    owner     => $xplore_owner,
    group     => $xplore_group,
    content   => template('documentum/xplore/indexagent.properties.erb'),
  }

  file { 'ia-serviceConfig':
    ensure    => file,
    path      => "/etc/default/${service_name}.conf",
    owner     => root,
    group     => root,
    mode      => 755,
    content   => template('documentum/xplore/service.conf.erb'),
  }

  file { 'ia-serviceStartScript':
    ensure    => file,
    path      => "/etc/init.d/${service_name}",
    owner     => root,
    group     => root,
    mode      => 755,
    content   => template('documentum/xplore/service.erb'),
  }

  exec {'chkconfig-ia':
    require     => [File["ia-serviceConfig"],
                    File["ia-serviceStartScript"],
                  ],
    command  => "/sbin/chkconfig --add ${ia_service_name}; /sbin/chkconfig ${ia_service_name} on",
    onlyif    =>  "/usr/bin/test `/sbin/chkconfig --list | /bin/grep ${ia_service_name} | /usr/bin/wc -l` -eq 0",
  }

  exec { "ia-create":
    command     => "${xplore_home}/setup/indexagent/iaConfig.bin LAX_VM ${xplore_home}/java64/1.8.0_77/jre/bin/java -f ${installer_location}/ia/indexagent.properties -r ${installer_location}/ia/response.properties",
    cwd         => "${xplore_home}/setup/indexagent",
    require     => [File["ia-response"],
                    User["${xplore_owner}"],
                    ],
    environment => ["HOME=/home/${xplore_owner}",
                    ],
    creates     => "${xplore_home}/wildfly9.0.1/server/start${ia_service_name}.sh",
    user        => $xplore_owner,
    group       => $xplore_group,
    logoutput   => true,
    timeout     => 3000,
  }

  service { $ia_service_name:
    ensure  => running,
    enable  => true,
    require => [Exec["chkconfig-ia"],
                Exec["ia-create"],
                File["ia-serviceConfig"],
                File["ia-serviceStartScript"],]
  }
}
