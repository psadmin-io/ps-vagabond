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

function copy_modules() {

  # Copy io_ DPK code
  # -----------------------------
  Write-Host "[${computername}][Task] Update DPK with custom modules"
  # copy-item c:\vagrant\site.pp C:\ProgramData\PuppetLabs\puppet\etc\manifests\site.pp -force
  copy-item c:\vagrant\modules\* "${PUPPET_HOME}\modules\" -recurse -force
  Write-Host "[${computername}][Done] Update DPK with custom modules" -ForegroundColor green

}

function set_dpk_role() {
  Write-Host "[${computername}][Task] Update DPK Role in site.pp"
  (Get-Content "${PUPPET_HOME}\manifests\site.pp") -replace 'include.*', "include ${DPK_ROLE}" | Set-Content "${PUPPET_HOME}\manifests\site.pp"
  Write-Host "[${computername}][Task] Update DPK Role in site.pp"
}

#-----------------------------------------------------------[Execution]-----------------------------------------------------------

. copy_modules
. set_dpk_role

Write-Host "DPK Module Sync Complete"
