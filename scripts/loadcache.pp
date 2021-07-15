$ps_home_dir          = hiera('ps_home_location')
$oracle_home_location = hiera('oracle_server_location')
$tns_dir              = hiera('tns_dir')

case $::osfamily {
  'windows': {
    $gem_home = 'c:/program files/puppet labs/puppet/bin'
    exec { 'install-psadmin_plus':
      command  => "${gem_home}/gem install psadmin_plus",
      provider => 'powershell'
    }
  }
  'RedHat', 'linux': {
    $gem_home = '/opt/puppetlabs/puppet/bin'
    exec { 'install-psadmin_plus':
      command => "${gem_home}/gem install psadmin_plus",
    }
  }
}

$prcs_domain_name = hiera('prcs_domain_name')

$appserver_domain_list = hiera('appserver_domain_list')
$appserver_domain_list.each | $domain_name, $app_domain_info | {

  $db_settings = $app_domain_info['db_settings']
  $db_settings_array  = join_keys_to_values($db_settings, '=')
  $ps_cfg_home_dir = $app_domain_info['ps_cfg_home_dir']

  case $::osfamily {
    'windows': {
      exec {"LOADCACHE-${domain_name}":
        command  => "\$env:PS_HOME=\"${ps_home_dir}\";\
        \$env:ORACLE_HOME=\"${oracle_home_location}\";\
        \$env:TNS_ADMIN=\"${tns_dir}\";\
        \$env:PATH=\"\${env:PS_HOME}\\bin\\client\\winx86;\${env:ORACLE_HOME}\\bin;\${env:PATH}\";\
        psae -CT ${db_settings[db_type]} -CD ${db_settings[db_name]} -CI ${db_settings[db_connect_id]} -CW ${db_settings[db_connect_pwd]} -CO ${db_settings[db_opr_id]} -CP ${db_settings[db_opr_pwd]} -R BUILD -AI LOADCACHE",
        provider => 'powershell'
      }
      -> exec {'copy-cache-folder':
        command  => "remove-item ${ps_cfg_home_dir}/appserv/${domain_name}/CACHE/*; \
                     copy-item -recurse ${ps_cfg_home_dir}/CLIENT/CACHE/${prcs_domain_name}/stage/stage/ ${ps_cfg_home_dir}/appserv/${domain_name}/CACHE/SHARE/",
        provider => 'powershell',
      }
      -> exec { "Set-Cache-Mode-${domain_name}":
        command  => "(gc ${ps_cfg_home_dir}/appserv/${domain_name}/psappsrv.cfg) | %{ \$_ -replace \";ServerCacheMode=0\",\"ServerCacheMode=1\" } | set-content ${ps_cfg_home_dir}/appserv/${domain_name}/psappsrv.cfg",
        provider => 'powershell',
      }
      -> exec { "Bounce ${domain_name} App Domain":
        command  => "psa bounce app ${domain_name}",
        provider => 'powershell',
        require  => Exec['install-psadmin_plus'],
      }
    }
    'RedHat', 'linux': {
      pt_psae {"LOADCACHE-${domain_name}":
        db_settings    => $db_settings_array,
        run_control_id => 'BUILD',
        program_id     => 'LOADCACHE',
        os_user        => 'psadm2',
        logoutput      => 'true',
        ps_home_dir    => $ps_home_dir,
      }
      -> file {"${ps_cfg_home_dir}/appserv/${domain_name}/CACHE/SHARE":
        ensure => link,
        target => '/home/psadm2/PS_CACHE/CACHE/STAGE/stage'
      }
      -> exec { "Set-Cache-Mode-${domain_name}":
        command => "sed -i 's/^\;ServerCacheMode=0/ServerCacheMode=1/' ${ps_cfg_home_dir}/appserv/${domain_name}/psappsrv.cfg",
        path    => '/usr/bin',
      }
      -> exec { "Bounce ${domain_name} App Domain":
        command => "${gem_home}/psa bounce app ${domain_name}",
        require => Exec['install-psadmin_plus'],
      }
    }
  }

}