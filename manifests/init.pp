# == Class: documentum
#
# Performs initial configuration tasks for all Vagrant boxes.
# http://www.puppetcookbook.com/posts/add-a-unix-group.html
# https://docs.puppetlabs.com/guides/techniques.html#how-can-i-ensure-a-group-exists-before-creating-a-user
# http://theruddyduck.typepad.com/theruddyduck/2013/11/using-puppet-to-configure-users-groups-and-passwords-for-cloudera-manager.html
# http://stackoverflow.com/questions/19024134/calling-puppet-defined-resource-with-multiple-parameters-multiple-times

class documentum (
  $installer_location,
  $source_location,
  $documentum,
  $dctm_owner,
  $dctm_group,
  $version,
  $jms_port,
  $jms_service,
  $bof_registry_password,
  $oracle_home,

  $docbroker_required,
  $docbroker_host = undef,
  $docbroker_port = undef,
  $docbroker_name = undef,

  $repository_required,
  $repository_name = undef,
  $repository_id = undef,
  $repository_service = undef,
  $repository_desc = undef,
  $repository_data_dir = undef,
  $db_user = undef,
  $db_password = undef,
  $db_tablespace = undef,
  $db_connection = undef,
  ){
  ## ensuring user has correct profile settings
  file { "/home/${dctm_owner}/.bashrc":
      owner => $dctm_owner,
      group => $dctm_group,
      mode  => '0644',
      source => 'puppet:///modules/documentum/bashrc.sh';
  }

  documentum::contentserver::server { 'server':
    installer_location    => "${installer_location}/cs",
    source_location       => $source_location,
    documentum            => $documentum,
    dctm_owner            => $dctm_owner,
    version               => $version,
    jms_port              => $jms_port,
    jms_service           => $jms_service,
    bof_registry_password => $bof_registry_password,
    oracle_home           => $oracle_home,
  }

  documentum::contentserver::roottask { 'root':
    documentum            => $documentum,
    version               => $version,
    require               => Documentum::Contentserver::Server['server'],
  }

  if $docbroker_required == true {
    documentum::contentserver::docbroker { $docbroker_name:
      installer_location    => $installer_location,
      documentum            => $documentum,
      dctm_owner            => $dctm_owner,
      dctm_group            => $dctm_group,
      version               => $version,
      docbroker_port        => $docbroker_port,
      docbroker_host        => $docbroker_host,
      require               => Documentum::Contentserver::Roottask['root'],
    }
  }

  if $repository_required == true {
    documentum::contentserver::repository { $repository_name:
      installer_location    => $installer_location,
      documentum            => $documentum,
      dctm_owner            => $dctm_owner,
      dctm_group            => $dctm_group,
      version               => $version,
      docbroker_port        => $docbroker_port,
      docbroker_host        => $docbroker_host,
      docbroker_name        => $docbroker_name,
      repository_id         => $repository_id,
      repository_service    => $repository_service,
      repository_desc       => $repository_desc,
      repository_host       => $repository_host,
      repository_data_dir   => $repository_data_dir,
      db_user               => $db_user,
      db_password           => $db_password,
      db_connection         => $db_connection,
      db_tablespace         => $db_tablespace,
      oracle_home           => $oracle_home,
      bof_registry_password => $bof_registry_password,
      require               => Documentum::Contentserver::Docbroker[$docbroker_name],
    }
  }
}
