$peoplesoft_base      = hiera('peoplesoft_base')
$ps_home_dir          = hiera('ps_home_location')
$oracle_home_location = hiera('oracle_server_location')
$tns_dir              = hiera('tns_dir')
$gem_home             = "${peoplesoft_base}/psft_puppet_agent/bin"

$prcs_domain_name = hiera('prcs_domain_name')
$db_name = hiera('db_name')

$preload_script_win = @(END)
if (! ( Test-Path <%= $gem_home %>/gem.bat )) {
    Write-Output "Installing psadmin_plus"
    Invoke-WebRequest https://rubygems.org/downloads/psadmin_plus-2.0.5.gem -outFile psadmin_plus.gem
    <%= $gem_home %>/gem.bat install psadmin_plus --local
}

Write-Output "Stopping app server"
<%= $gem_home %>/psa.bat stop app <%= $domain_name %>

$env:PS_HOME="<%= $ps_home_dir %>";
$env:ORACLE_HOME="<%= $oracle_home_location %>";
$env:TNS_ADMIN="<%= $tns_dir %>";
$env:PATH="${env:PS_HOME}\bin\client\winx86;${env:ORACLE_HOME}\bin;${env:PATH}";

Write-Output "Running LOADCACHE"
& ${env:PS_HOME}/bin/client/winx86/psae.exe -CT <%= $db_settings[db_type] %> -CD <%= $db_settings[db_name] %> -CI <%= $db_settings[db_connect_id] %> -CW <%= $db_settings[db_connect_pwd] %> -CO <%= $db_settings[db_opr_id] %> -CP <%= $db_settings[db_opr_pwd] %> -R BUILD -AI LOADCACHE

Write-Output "Copy CACHE files to app server"
remove-item -recurse -force <%= $ps_cfg_home_dir %>/appserv/<%= $domain_name %>/CACHE/*;
mkdir -force <%= $ps_cfg_home_dir %>/appserv/<%= $domain_name %>/CACHE/SHARE/
copy-item -recurse <%= $ps_cfg_home_dir %>/CLIENT/CACHE/<%= $db_name %>/stage/stage/* <%= $ps_cfg_home_dir %>/appserv/<%= $domain_name %>/CACHE/SHARE/

Write-Output "Configure app server for Shared Cache"
(gc <%= $ps_cfg_home_dir %>/appserv/<%= $domain_name %>/psappsrv.cfg) | %{ $_ -replace ";ServerCacheMode=0","ServerCacheMode=1" } | set-content <%= $ps_cfg_home_dir %>/appserv/<%= $domain_name %>/psappsrv.cfg

Write-Output "Starting app server"
<%= $gem_home %>/psa.bat bounce app <%= $domain_name %>
END

$appserver_domain_list = hiera('appserver_domain_list')
$appserver_domain_list.each | $domain_name, $app_domain_info | {

  $db_settings = $app_domain_info['db_settings']
  $db_settings_array  = join_keys_to_values($db_settings, '=')
  $ps_cfg_home_dir = $app_domain_info['ps_cfg_home_dir']

  case $::osfamily {
    'windows': {
      
      notify { 'Creating and running preloaccache.ps1 ': }
      file { "${peoplesoft_base}/preloadcache.ps1":
        ensure  => file,
        content => inline_epp($preload_script_win),
      } ->
      exec {'Load-Cache':
        command => "C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -File ${peoplesoft_base}/preloadcache.ps1"
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
