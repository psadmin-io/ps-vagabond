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
        provision-puppet.ps1 -PUPPET_HOME C:\ProgramData\PuppetLabs\puppet\etc -PT_VERSION 856

#>

#-----------------------------------------------------------[Parameters]----------------------------------------------------------

[CmdletBinding()]
Param(
  [String]$PUPPET_HOME = $env:PUPPET_HOME,
  [String]$PT_VERSION  = $env:PT_VERSION
)


#---------------------------------------------------------[Initialization]--------------------------------------------------------

# Valid values: "Stop", "Inquire", "Continue", "Suspend", "SilentlyContinue"
$ErrorActionPreference = "Stop"
$DebugPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"

#------------------------------------------------------------[Variables]----------------------------------------------------------

$DEBUG = "true"

#-----------------------------------------------------------[Functions]-----------------------------------------------------------


function execute_puppet_apply() {
  Write-Host "Applying Puppet manifests"
  # Reset Environment and PATH to include bin\puppet
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

  if ($PT_VERSION -eq "856") {
    if ($DEBUG -eq "true") {
      . refreshenv
      puppet apply "${PUPPET_HOME}\production\manifests\site.pp" --confdir="${PUPPET_HOME}" --trace --debug
    } else {
      . refreshenv | out-null
      puppet apply "${PUPPET_HOME}\production\manifests\site.pp" 2>&1 | out-null
    }
   }
  else {
    if ($DEBUG -eq "true") {
      . refreshenv
      puppet apply "${PUPPET_HOME}\manifests\site.pp" --trace --debug
    } else {
      . refreshenv | out-null
      puppet apply "${PUPPET_HOME}\manifests\site.pp" 2>&1 | out-null
    }
  }
}

#-----------------------------------------------------------[Execution]-----------------------------------------------------------

. execute_puppet_apply

# $fqdn = facter fqdn
# $port = hiera pia_http_port
# $sitename = hiera pia_site_name

# Write-Host "Your login URL is http://${fqdn}:${port}/${sitename}/signon.html" -ForegroundColor White