#Requires -Version 5

<#PSScriptInfo

    .VERSION 1.0

    .GUID cad7db76-01e8-4abd-bdb9-3fca50cadbc7

    .AUTHOR psadmin.io

    .SYNOPSIS
        ps-vagabond provisioning puppet

    .DESCRIPTION
        Provisioning script for ps-vagabond to copy custom yaml and run puppet apply

    .PARAMETER PUPPET_HOME
        Puppet home directory

    .EXAMPLE
        provision-puppet.ps1 -PUPPET_HOME C:\ProgramData\PuppetLabs\puppet\etc

#>

#-----------------------------------------------------------[Parameters]----------------------------------------------------------

[CmdletBinding()]
Param(
  [String]$PUPPET_HOME = $env:PUPPET_HOME
)


#---------------------------------------------------------[Initialization]--------------------------------------------------------

# Valid values: "Stop", "Inquire", "Continue", "Suspend", "SilentlyContinue"
$ErrorActionPreference = "Stop"
$DebugPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"

#------------------------------------------------------------[Variables]----------------------------------------------------------

$DEBUG = "false"

#-----------------------------------------------------------[Functions]-----------------------------------------------------------

function copy_customizations_file() {
  Write-Host "Copying customizations file"
  if ($DEBUG -eq "true") {
    Write-Host "Copying to ${PUPPET_HOME}\data"
    Copy-Item "c:\vagrant\config\psft_customizations.yaml" "${PUPPET_HOME}\data\psft_customizations.yaml" -Force
  } else {
    Copy-Item "c:\vagrant\config\psft_customizations.yaml" "${PUPPET_HOME}\data\psft_customizations.yaml" -Force 2>&1 | out-null
  }
}

function execute_puppet_apply() {
  Write-Host "Applying Puppet manifests"
  # Reset Environment and PATH to include bin\puppet
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
  . refreshenv
  if ($DEBUG -eq "true") {
    puppet apply "${PUPPET_HOME}\manifests\site.pp" --trace --debug
  } else {
    puppet apply "${PUPPET_HOME}\manifests\site.pp" | out-null
  }
}

#-----------------------------------------------------------[Execution]-----------------------------------------------------------

. copy_customizations_file
. execute_puppet_apply