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
  [String]$PUPPET_HOME      = $env:PUPPET_HOME,
  [String]$DPK_ROLE         = $env:DPK_ROLE
)


#---------------------------------------------------------[Initialization]--------------------------------------------------------

# Valid values: "Stop", "Inquire", "Continue", "Suspend", "SilentlyContinue"
$ErrorActionPreference = "Stop"
$DebugPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"

#------------------------------------------------------------[Variables]----------------------------------------------------------

$DEBUG = "false"

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
       "56" {
          $PUPPET_HOME = "${PSFT_BASE_DIR}/dpk/puppet"
       }
      Default { Write-Host "PeopleTools version could not be determined in the bs-manifest file."}
  }  

  if ($DEBUG -eq "true" ) {
      Write-Host "Tools Minor Version: ${TOOLS_MINOR_VERSION}"
      Write-Host "Puppet Home Directory: ${PUPPET_HOME}"
  }
}

function copy_modules() {

  # Copy io_ DPK code
  # -----------------------------
  Write-Host "[${computername}][Task] Update DPK with custom modules"
  # copy-item c:\vagrant\site.pp C:\ProgramData\PuppetLabs\puppet\etc\manifests\site.pp -force
  switch ($TOOLS_MINOR_VERSION){
    "56" {  
      copy-item c:\vagrant\modules\* "${PUPPET_HOME}\production\modules\" -recurse -force
    } 
    "55" {
      copy-item c:\vagrant\modules\* "${PUPPET_HOME}\modules\" -recurse -force
    }
  }
  Write-Host "[${computername}][Done] Update DPK with custom modules" -ForegroundColor green

}

function fix_dpk_bugs() {
  # Fix Tuxedo Features Separator Bug
  # ---------------------------------
  Write-Host "[${computername}][Task] Fix DPK Bugs"
  (Get-Content C:\ProgramData\PuppetLabs\puppet\etc\modules\pt_config\lib\puppet\provider\psftdomain.rb).replace("feature_settings_separator = '#'","feature_settings_separator = '/'") | set-content C:\ProgramData\PuppetLabs\puppet\etc\modules\pt_config\lib\puppet\provider\psftdomain.rb
  Write-Host "[${computername}][Done] Fix DPK Bugs" -ForegroundColor green

}
function set_dpk_role() {
  Write-Host "[${computername}][Task] Update DPK Role in site.pp"
  switch ($TOOLS_MINOR_VERSION) {
    "56" {
      (Get-Content "${PUPPET_HOME}\production\manifests\site.pp") -replace 'include.*', "include ${DPK_ROLE}" | Set-Content "${PUPPET_HOME}\production\manifests\site.pp"
    }
    "55" {
      (Get-Content "${PUPPET_HOME}\manifests\site.pp") -replace 'include.*', "include ${DPK_ROLE}" | Set-Content "${PUPPET_HOME}\manifests\site.pp"
    }
  }
  Write-Host "[${computername}][Task] Update DPK Role in site.pp"
}

#-----------------------------------------------------------[Execution]-----------------------------------------------------------

. determine_tools_version
. determine_puppet_home
. copy_modules

if ($TOOLS_MINOR_VERSION -eq "55") {
  . fix_dpk_bugs
}
if (! ($DPK_ROLE -eq '')) {
  . set_dpk_role
}

Write-Host "DPK Module Sync Complete"
