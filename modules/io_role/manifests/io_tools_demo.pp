class io_role::io_tools_demo inherits pt_role::pt_base {

  notify { "Applying io_role::io_tools_demo": }

  $ensure   = hiera('ensure')
  $env_type = hiera('env_type')

  contain ::pt_profile::pt_app_deployment
  contain ::pt_profile::pt_tools_deployment
  contain ::pt_profile::pt_oracleserver
  contain ::pt_profile::pt_psft_environment
  contain ::pt_profile::pt_psft_db
  contain ::pt_profile::pt_appserver
  contain ::pt_profile::pt_prcs
  contain ::pt_profile::pt_pia
  contain ::io_profile::io_web
  contain ::pt_profile::pt_samba
  contain ::pt_profile::pt_source_details

  if $ensure == present {
    contain ::pt_profile::pt_tools_preboot_config
    contain ::pt_profile::pt_domain_boot
    contain ::pt_profile::pt_tools_postboot_config

    Class['::pt_profile::pt_system'] ->
    Class['::pt_profile::pt_app_deployment'] ->
    Class['::pt_profile::pt_tools_deployment'] ->
    Class['::pt_profile::pt_oracleserver'] ->
    Class['::pt_profile::pt_psft_environment'] ->
    Class['::pt_profile::pt_psft_db'] ->
    Class['::pt_profile::pt_appserver'] ->
    Class['::pt_profile::pt_prcs'] ->
    Class['::pt_profile::pt_pia'] ->
    Class['::io_profile::io_web'] ->
    Class['::pt_profile::pt_samba'] ->
    Class['::pt_profile::pt_tools_preboot_config'] ->
    Class['::pt_profile::pt_domain_boot'] ->
    Class['::pt_profile::pt_tools_postboot_config'] -> 
    Class['::pt_profile::pt_source_details'] 
  }
  elsif $ensure == absent {
    Class['::pt_profile::pt_source_details'] ->
    Class['::pt_profile::pt_samba'] ->
    Class['::io_profile::io_web'] ->
    Class['::pt_profile::pt_pia'] ->
    Class['::pt_profile::pt_prcs'] ->
    Class['::pt_profile::pt_appserver'] ->
    Class['::pt_profile::pt_psft_db'] ->
    Class['::pt_profile::pt_psft_environment'] ->
    Class['::pt_profile::pt_oracleserver'] ->
    Class['::pt_profile::pt_tools_deployment'] ->
    Class['::pt_profile::pt_app_deployment'] ->
    Class['::pt_profile::pt_system']
  }
}
