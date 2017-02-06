# == Class: xplore
#
# Performs initial configuration tasks for all Vagrant boxes.
# http://www.puppetcookbook.com/posts/add-a-unix-group.html
# https://docs.puppetlabs.com/guides/techniques.html#how-can-i-ensure-a-group-exists-before-creating-a-user
# http://theruddyduck.typepad.com/theruddyduck/2013/11/using-puppet-to-configure-users-groups-and-passwords-for-cloudera-manager.html
# http://stackoverflow.com/questions/19024134/calling-puppet-defined-resource-with-multiple-parameters-multiple-times

class documentum::xplore (
  $installer_location,
  $source_location,
  $xplore_home,
  $version,
  $xplore_owner,
  $xplore_group,
  $xplore_data,
  $xplore_config,

  $dsearch_required,
  $dsearch_service = undef,
  $dsearch_host = undef,
# note this should only be the first two ports, eg if 9300, use 93
  $dsearch_port = undef,
  $dsearch_admin = undef,
  $dsearch_password = undef,

  $ia_required,
  $ia_service_name = undef,
  $ia_host = undef,
  $ia_port = undef,
  $ia_password = undef,
  $ia_storage = undef,

  $repository = undef,
  $repository_user = undef,
  $repository_password = undef,
  $docbroker_host = undef,
  $docbroker_port = undef,
  $globalrepo = undef,
  $globaluser = undef,
  $globalpassword = undef,
  ){
  file { "/home/${xplore_owner}/.bashrc":
      owner => $xplore_owner,
      group => $xplore_group,
      mode  => '0644',
      source => 'puppet:///modules/documentum/bashrc.sh';
  }

  documentum::xplore::server {'server':
    installer_location => $installer_location,
    source_location    => $source_location,
    xplore_home        => $xplore_home,
    version            => $version,
    xplore_owner       => $xplore_owner,
    xplore_group       => $xplore_group,
  }

  if $dsearch_required == true {
    documentum::xplore::dsearch {$dsearch_service:
      installer_location => $installer_location,
      xplore_home        => $xplore_home,
      xplore_owner       => $xplore_owner,
      xplore_group       => $xplore_group,
      xplore_data        => $xplore_data,
      xplore_config      => $xplore_config,

      dsearch_service    => $dsearch_service,
      dsearch_host       => $dsearch_host,
      dsearch_port       => $dsearch_port,
      dsearch_admin      => $dsearch_admin,
      dsearch_password   => $dsearch_password,
      require            => Documentum::Xplore::Server['server'],
    }
  }

  if $ia_required == true {
    documentum::xplore::indexagent {$ia_service_name:
      installer_location  => $installer_location,
      xplore_home         => $xplore_home,
      version             => $version,
      xplore_owner        => $xplore_owner,
      xplore_group        => $xplore_group,

      dsearch_host        => $dsearch_host,
      dsearch_port        => $dsearch_port,

      ia_service_name     => $ia_service_name,
      ia_host             => $ia_host,
      ia_port             => $ia_port,
      ia_password         => $ia_password,
      ia_storage          => $ia_storage,

      repository          => $repository,
      repository_user     => $repository_user,
      repository_password => $repository_password,
      docbroker_host      => $docbroker_host,
      docbroker_port      => $docbroker_port,
      globalrepo          => $globalrepo,
      globaluser          => $globaluser,
      globalpassword      => $globalpassword,

      require             => Documentum::Xplore::Dsearch[$dsearch_service],
    }
  }
}
