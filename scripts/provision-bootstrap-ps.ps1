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
        {$_ -in "56", "57", "58"} {
            $PUPPET_HOME = "${PSFT_BASE_DIR}/dpk/puppet"
        }
        Default { Write-Host "PeopleTools version could not be determined in the bs-manifest file."}
    }  

    if ($DEBUG -eq "true" ) {
        Write-Host "Puppet Home Directory: ${PUPPET_HOME}"
    }
}

function generate_response_file() {
    $file = New-Item -type file "${DPK_INSTALL}/response.cfg" -force
    $template=@"
psft_base_dir = "${PSFT_BASE_DIR}"
install_type = "PUM"
env_type  = "fulltier"
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
"@ 

    if ($DEBUG -eq "true") {
        Write-Host "Response File Template: ${template}"
        Write-Host "Writing to location: ${file}"
    }
    $template | out-file $file -Encoding ascii
}
function execute_psft_dpk_setup() {

  # $begin=$(get-date)
  Write-Host "Executing DPK setup script"
  Write-Host "DPK INSTALL: ${DPK_INSTALL}"

  switch ($TOOLS_MINOR_VERSION) {
    {$_ -in "56", "57", "58"} {
        Write-Host "Running PeopleTools 8.$_ Bootstrap Script"
        if ($DEBUG -eq "true") {
            . "${DPK_INSTALL}/setup/psft-dpk-setup.bat" `
            --silent `
            --dpk_src_dir "${DPK_INSTALL}" `
            --response_file "${DPK_INSTALL}/response.cfg" `
            --no_puppet_run
        } else {
            . "${DPK_INSTALL}/setup/psft-dpk-setup.bat" `
            --dpk_src_dir ${DPK_INSTALL} `
            --silent `
            --response_file "${DPK_INSTALL}/response.cfg" `
            --no_puppet_run 2>&1 | out-null
        }
    }  
    "55" {
        if ($DEBUG -eq "true") {
            . "${DPK_INSTALL}/setup/psft-dpk-setup.ps1" `
            -dpk_src_dir=$(resolve-path $DPK_INSTALL).path `
            -silent `
            -no_env_setup
        } else {
            . "${DPK_INSTALL}/setup/psft-dpk-setup.ps1" `
            -dpk_src_dir=$(resolve-path $DPK_INSTALL).path `
            -silent `
            -no_env_setup 2>&1 | out-null
        }
    }
  } # end switch
}

. determine_tools_version
. determine_puppet_home
. generate_response_file
. execute_psft_dpk_setup