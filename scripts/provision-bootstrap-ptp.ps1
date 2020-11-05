#Requires -Version 5

<#PSScriptInfo

    .VERSION 1.0

    .GUID cad7db76-01e8-4abd-bdb9-3fca50cadbc7

    .AUTHOR psadmin.io

    .SYNOPSIS
        ps-vagabond provisioning boot

    .DESCRIPTION
        Provisioning bootstrap script for ps-vagabond

    .PARAMETER PATCH_ID
        Patch ID for the PUM image

    .PARAMETER MOS_USERNAME
        My Oracle Support Username

    .PARAMETER MOS_PASSWORD
        My Oracle Support Password

    .PARAMETER DPK_INSTALL
        Directory to use for downloading the DPK files

    .EXAMPLE
        provision-boot.ps1 -PATCH_ID 23711856 -MOS_USERNAME user@example.com -MOS_PASSWORD mymospassword -DPK_INSTALL C:/peoplesoft/dpk/fn92u020

#>

#-----------------------------------------------------------[Parameters]----------------------------------------------------------

[CmdletBinding()]
Param(
  [String]$PATCH_ID         = $env:PATCH_ID,
  [String]$DPK_INSTALL      = $env:DPK_INSTALL,
  [String]$PTP_INSTALL      = $env:PTP_INSTALL,
  [String]$PSFT_BASE_DIR    = $env:PSFT_BASE_DIR,
  [String]$PUPPET_HOME      = $env:PUPPET_HOME
)


#---------------------------------------------------------[Initialization]--------------------------------------------------------

# Valid values: "Stop", "Inquire", "Continue", "Suspend", "SilentlyContinue"
$ErrorActionPreference = "Stop"
$DebugPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"

#------------------------------------------------------------[Variables]----------------------------------------------------------

$DEBUG = "true"
$computername = $env:computername

function determine_tools_version() {
  $TOOLS_VERSION = $(Get-Content ${DPK_INSTALL}/setup/bs-manifest | select-string "version" | % {$_.line.split("=")[1]})
  $TOOLS_MAJOR_VERSION = $TOOLS_VERSION.split(".")[0]
  $TOOLS_MINOR_VERSION = $TOOLS_VERSION.split(".")[1]
  $TOOLS_PATCH_VERSION = $TOOLS_VERSION.split(".")[2]

  if ($DEBUG -eq "true") {
      Write-Host "Tools Version: ${TOOLS_VERSION}"
      Write-Host "Tools Major Version: ${TOOLS_MAJOR_VERSION}"
      Write-Host "Tools Minor Version: ${TOOLS_MINOR_VERSION}"
      Write-Host "Tools Patch Version: ${TOOLS_PATCH_VERSION}"
  }
}

function determine_puppet_home() {
  switch ($TOOLS_MINOR_VERSION) {
      "55" { 
          $PUPPET_HOME = "C:\ProgramData\PuppetLabs\puppet\etc"
      }
      "56" {
        $PUPPET_HOME = "${PSFT_BASE_DIR}/dpk/puppet"
        Write-Host "PeopleTools Patching for 8.56 is not supported yet."
        exit
      }
      "57" {
        $PUPPET_HOME = "${PSFT_BASE_DIR}/dpk/puppet"
        Write-Host "PeopleTools Patching for 8.57 is not supported yet."
        exit
      }
      Default { Write-Host "PeopleTools version could not be determined in the bs-manifest file."}
  }  

  if ($DEBUG -eq "true" ) {
      Write-Host "Puppet Home Directory: ${PUPPET_HOME}"
  }
}

function generate_response_file() {
  $file = New-Item -type file "${PTP_INSTALL}/response.cfg" -force
  $template=@"
psft_base_dir = "${PSFT_BASE_DIR}"
install_type = "PUM"
env_type  = "midtier"
db_type = "DEMO"
db_name = "PSFTDB"
db_service_name = "PSFTDB"
db_host = "localhost"
admin_pwd = "Passw0rd_"
connect_pwd = "peop1e"
access_pwd  = "SYSADM"
opr_pwd = "PS"
# domain_conn_pwd = "P@ssw0rd_"
weblogic_admin_pwd  = "Passw0rd#"
webprofile_user_pwd = "PTWEBSERVER"
gw_user_pwd = "password"
gw_keystore_pwd = "password"
"@ 

  if ($DEBUG -eq "true") {
      Write-Host "Response File Template: ${template}"
      Write-Host "Writing to location: ${file}"
  }
  $template | out-file $file -Encoding ascii
}

function generate_psft_setup_file() {
  $file = New-Item -type file "${DPK_INSTALL}/setup/scripts/platform/psft_setup.props" -force
  $template=@"
psft_base_dir="${PSFT_BASE_DIR}"
"@
}

function change_to_midtier() {
  Write-Host "[${computername}][Task] Change env_type to 'midtier'"
  switch ($TOOLS_MINOR_VERSION) {
    "57" {
      (Get-Content "${PUPPET_HOME}\production\data\defaults.yaml").replace("env_type: fulltier", "env_type: midtier") | Set-Content "${PUPPET_HOME}\production\data\defaults.yaml"
      (Get-Content "${PUPPET_HOME}\production\manifests\site.pp") -replace 'include.*', "include ::pt_role::pt_tools_deployment" | Set-Content "${PUPPET_HOME}\production\manifests\site.pp"

    }
    "56" {
      (Get-Content "${PUPPET_HOME}\production\data\defaults.yaml").replace("env_type: fulltier", "env_type: midtier") | Set-Content "${PUPPET_HOME}\production\data\defaults.yaml"
      (Get-Content "${PUPPET_HOME}\production\manifests\site.pp") -replace 'include.*', "include ::pt_role::pt_tools_deployment" | Set-Content "${PUPPET_HOME}\production\manifests\site.pp"

    }
    "55" {
      (Get-Content "${PUPPET_HOME}\data\defaults.yaml").replace("env_type: fulltier", "env_type: midtier") | Set-Content "${PUPPET_HOME}\data\defaults.yaml"
      (Get-Content "${PUPPET_HOME}\manifests\site.pp") -replace 'include.*', "include ::pt_role::pt_tools_deployment" | Set-Content "${PUPPET_HOME}\manifests\site.pp"
    }
  }
  
  Write-Host "[${computername}][Done] Change env_type to 'midtier'"
}

function execute_dpk_cleanup() {
  Write-Host "[${computername}][Task] Run the DPK cleanup script"
  Write-Host "DPK INSTALL: ${DPK_INSTALL}"

  Stop-Service psft* -ErrorAction SilentlyContinue
  if (get-process -name rmiregistry -ErrorAction SilentlyContinue) {
    get-process -name rmiregistry | stop-process -force
  }
  if (get-service -name "*ProcMgr*") {
    Stop-Service -name "*ProcMGR*" -ErrorAction SilentlyContinue
  }

  # Remove Git from PATH to prevent `id` error when running Puppet
  # . remove_from_PATH("C\:\\Program\ Files\\Git\\usr\\bin")
  if (Test-Path "C:\Program Files\Git\usr\bin\id.exe") {
    move-item "C:\Program Files\Git\usr\bin\id.exe" "C:\Program Files\Git\usr\bin\_id.exe"
  }

  Write-Host "Running the Bootstrap Cleanup Script"
  switch ($TOOLS_MINOR_VERSION) {
    "57" {
      if ($DEBUG -eq "true") {
          . "${PTP_INSTALL}/setup/psft-dpk-setup.bat" `
          --cleanup `
          --silent `
          --response_file "${PTP_INSTALL}/response.cfg"
      } else {
          . "${PTP_INSTALL}/setup/psft-dpk-setup.bat" `
          --cleanup `
          --silent `
          --response_file "${PTP_INSTALL}/response.cfg" 2>&1 | out-null
      }
    } 
    "56" {
      if ($DEBUG -eq "true") {
          . "${PTP_INSTALL}/setup/psft-dpk-setup.bat" `
          --cleanup `
          --silent `
          --response_file "${PTP_INSTALL}/response.cfg"
      } else {
          . "${PTP_INSTALL}/setup/psft-dpk-setup.bat" `
          --cleanup `
          --silent `
          --response_file "${PTP_INSTALL}/response.cfg" 2>&1 | out-null
      }
    } 
    "55" {
      if ($DEBUG -eq "true") {
        . "${PTP_INSTALL}/setup/psft-dpk-setup.ps1" `
          -cleanup `
          -ErrorAction SilentlyContinue
      } else {
        . "${PTP_INSTALL}/setup/psft-dpk-setup.ps1" `
          -cleanup `
          -ErrorAction SilentlyContinue 2>&1 | out-null
      }
    }
  }

  Write-Host "[${computername}][Done] Run the DPK cleanup script"
}

function execute_psft_dpk_setup() {

  Write-Host "[${computername}][Task] Executing PeopleTools Patch DPK setup script"
  Write-Host "PTP INSTALL: ${PTP_INSTALL}"
  
  # $cfg_home = hiera ps_config_home
  # if (test-path $cfg_home) {
  #   remove-item "${cfg_home}" -recurse -force
  # }

  switch ($TOOLS_MINOR_VERSION) {
    "57" {
      Write-Host "Running PeopleTools 8.57 Bootstrap Script"
      if ($DEBUG -eq "true") {
          . "${PTP_INSTALL}/setup/psft-dpk-setup.bat" `
          --env_type midtier `
          --deploy_only `
          --response_file "${PTP_INSTALL}/response.cfg" `
          --dpk_src_dir "${PTP_INSTALL}" `
          --no_puppet_run
      } else {
          . "${PTP_INSTALL}/setup/psft-dpk-setup.bat" `
          --env_type midtier `
          --deploy_only `
          --response_file "${PTP_INSTALL}/response.cfg" `
          --dpk_src_dir ${PTP_INSTALL} `
          --no_puppet_run 2>&1 | out-null
      }
    } 
    "56" {
      Write-Host "Running PeopleTools 8.56 Bootstrap Script"
      if ($DEBUG -eq "true") {
          . "${PTP_INSTALL}/setup/psft-dpk-setup.bat" `
          --env_type midtier `
          --deploy_only `
          --response_file "${PTP_INSTALL}/response.cfg" `
          --dpk_src_dir "${PTP_INSTALL}" `
          --no_puppet_run
      } else {
          . "${PTP_INSTALL}/setup/psft-dpk-setup.bat" `
          --env_type midtier `
          --deploy_only `
          --response_file "${PTP_INSTALL}/response.cfg" `
          --dpk_src_dir ${PTP_INSTALL} `
          --no_puppet_run 2>&1 | out-null
      }
    } 
    "55" {
      if ($DEBUG -eq "true") {
        . "${PTP_INSTALL}/setup/psft-dpk-setup.ps1" `
          -dpk_src_dir=$(resolve-path $PTP_INSTALL).path `
          -env_type midtier `
          -deploy_only `
          -silent `
          -ErrorAction SilentlyContinue
      } else {
        . "${PTP_INSTALL}/setup/psft-dpk-setup.ps1" `
          -dpk_src_dir=$(resolve-path $PTP_INSTALL).path `
          -env_type midtier `
          -deploy_only `
          -silent `
          -ErrorAction SilentlyContinue 2>&1 | out-null
      }
    }
  }
  # Write-Host "`tUpdate env:PS_HOME to the new location"
  # [System.Environment]::SetEnvironmentVariable('PS_HOME', "$(hiera ps_home_location)", 'Machine');
  # Write-Host "`t`tPS_HOME: $(hiera ps_home_location)"
  Write-Host "[${computername}][Done] Executing PeopleTools Patch DPK setup script"
}

. determine_tools_version
. determine_puppet_home
. generate_response_file
. generate_psft_setup_file
. change_to_midtier
. execute_dpk_cleanup
# . execute_psft_dpk_setup