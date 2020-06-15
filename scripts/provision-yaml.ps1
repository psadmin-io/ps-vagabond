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

  if (!(Test-Path $PUPPET_HOME)) {
    New-Item -ItemType directory -Path $PUPPET_HOME
  }

  if ($DEBUG -eq "true" ) {
      Write-Host "Tools Minor Version: ${TOOLS_MINOR_VERSION}"
      Write-Host "Puppet Home Directory: ${PUPPET_HOME}"
  }
}
function copy_customizations_file() {
  Write-Host "Copying customizations file"
  switch ($TOOLS_MINOR_VERSION) {
    {$_ -in "56", "57", "58"} {
      if (!(Test-Path $PUPPET_HOME\production\data)) {
        New-Item -ItemType directory -Path $PUPPET_HOME\production\data
      }
      if ($DEBUG -eq "true") {
        Write-Host "Copying to ${PUPPET_HOME}\production\data"
        Copy-Item "c:\vagrant\config\psft_customizations.yaml" "${PUPPET_HOME}\production\data\psft_customizations.yaml" -Force
      } else {
        Copy-Item "c:\vagrant\config\psft_customizations.yaml" "${PUPPET_HOME}\production\data\psft_customizations.yaml" -Force 2>&1 | out-null
      }
    }
    "55" {
        if (!(Test-Path $PUPPET_HOME\data)) {
          New-Item -ItemType directory -Path $PUPPET_HOME\data
        }
      if ($DEBUG -eq "true") {
        Write-Host "Copying to ${PUPPET_HOME}\data"
        Copy-Item "c:\vagrant\config\psft_customizations.yaml" "${PUPPET_HOME}\data\psft_customizations.yaml" -Force
      } else {
        Copy-Item "c:\vagrant\config\psft_customizations.yaml" "${PUPPET_HOME}\data\psft_customizations.yaml" -Force 2>&1 | out-null
      }
    }
  }
}

#-----------------------------------------------------------[Execution]-----------------------------------------------------------

. determine_tools_version
. determine_puppet_home
. copy_customizations_file

Write-Host "YAML Sync Complete"

# $fqdn = facter fqdn
# $port = hiera pia_http_port
# $sitename = hiera pia_site_name

# Write-Host "Your login URL is http://${fqdn}:${port}/${sitename}/signon.html" -ForegroundColor White

