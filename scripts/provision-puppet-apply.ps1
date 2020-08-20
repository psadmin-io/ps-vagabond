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

#-----------------------------------------------------------[Functions]-----------------------------------------------------------


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
      Write-Host "Tools Minor Version: ${TOOLS_MINOR_VERSION}"
      Write-Host "Puppet Home Directory: ${PUPPET_HOME}"
  }
}

function execute_puppet_apply() {
  Write-Host "Applying Puppet manifests"
  # Reset Environment and PATH to include bin\puppet
  $env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

  switch ($TOOLS_MINOR_VERSION) {
    {$_ -in "56", "57", "58"} {
      if ($DEBUG -eq "true") {
        . refreshenv
        puppet apply "${PUPPET_HOME}\production\manifests\site.pp" --confdir="${PUPPET_HOME}" --trace --debug
      } else {
        . refreshenv | out-null
        puppet apply "${PUPPET_HOME}\production\manifests\site.pp" 2>&1 | out-null
      }
    }
    "55" {
      if ($DEBUG -eq "true") {
        . refreshenv
        puppet apply "${PUPPET_HOME}\manifests\site.pp" --trace --debug
      } else {
        . refreshenv | out-null
        puppet apply "${PUPPET_HOME}\manifests\site.pp" 2>&1 | out-null
      }
    }
  } # end switch
}

#-----------------------------------------------------------[Execution]-----------------------------------------------------------

. determine_tools_version
. determine_puppet_home
. execute_puppet_apply

# $fqdn = facter fqdn
# $port = hiera pia_http_port
# $sitename = hiera pia_site_name

# Write-Host "Your login URL is http://${fqdn}:${port}/${sitename}/signon.html" -ForegroundColor White