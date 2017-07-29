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
  [String]$PATCH_ID     = $env:PATCH_ID,
  [String]$DPK_INSTALL  = $env:DPK_INSTALL,
  [String]$PT_VERSION   = $env:PT_VERSION
)


#---------------------------------------------------------[Initialization]--------------------------------------------------------

# Valid values: "Stop", "Inquire", "Continue", "Suspend", "SilentlyContinue"
$ErrorActionPreference = "Stop"
$DebugPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"

#------------------------------------------------------------[Variables]----------------------------------------------------------

$DEBUG = "true"

function execute_psft_dpk_setup() {

  # $begin=$(get-date)
  Write-Host "Executing DPK setup script"
  Write-Host "DPK INSTALL: ${DPK_INSTALL}"

  if ($PT_VERSION -eq "856") {
      Write-Host "Running PeopleTools 8.56 Bootstrap Script"
    if ($DEBUG -eq "true") {
        . "${DPK_INSTALL}/setup/psft-dpk-setup.bat" `
        --silent `
        --dpk_src_dir "${DPK_INSTALL}" `
        --response_file "c:\vagrant\config\response.cfg" `
        --no_puppet_run
    } else {
        . "${DPK_INSTALL}/setup/psft-dpk-setup.bat" `
        --dpk_src_dir ${DPK_INSTALL} `
        --silent `
        --response_file c:\vagrant\config\response.cfg `
        --no_puppet_run 2>&1 | out-null
    }
  } else {
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
}

. execute_psft_dpk_setup