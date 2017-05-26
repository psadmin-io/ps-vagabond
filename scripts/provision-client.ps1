#Requires -Version 5

<#PSScriptInfo

    .VERSION 1.0

    .GUID cad7db76-01e8-4abd-bdb9-3fca50cadbc7

    .AUTHOR psadmin.io

    .SYNOPSIS
        ps-vagabond provisioning client

    .DESCRIPTION
        Provisioning script for ps-vagabond to install client tools

    .PARAMETER CA_SETUP
        Enable Change Assistant Setup

    .PARAMETER CA_PATH
        Change Assistant install path

    .PARAMETER CA_TYPE
        Change Assistant install type

    .PARAMETER CA_BACKUP
        Change Assistan backup option

    .PARAMETER PTF_SETUP
        Enable PeopleSoft Test Framework

    .EXAMPLE
        provision-client.ps1 -CA_SETUP true -CA_PATH c:\ptf -CA_TYPE upgrade -CA_BACKUP backup -PTF_SETUP true
#>

#-----------------------------------------------------------[Parameters]----------------------------------------------------------

[CmdletBinding()]
Param(
  [String]$CA_SETUP     = $env:CA_SETUP,
  [String]$CA_PATH      = $env:CA_PATH,
  [String]$CA_TYPE      = $env:CA_TYPE,
  [String]$CA_BACKUP    = $env:CA_BACKUP,
  [String]$PTF_SETUP    = $env:PTF_SETUP
)


#---------------------------------------------------------[Initialization]--------------------------------------------------------

# Valid values: "Stop", "Inquire", "Continue", "Suspend", "SilentlyContinue"
$ErrorActionPreference = "Stop"
$DebugPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"

#-----------------------------------------------------------[Variables]-----------------------------------------------------------
$SHORTCUTS = 'true'
$SECURITY  = 'true'
$BROWSER   = 'true'

#-----------------------------------------------------------[Functions]-----------------------------------------------------------

function execute_security_setup() {    
    Write-Host "Adding execute permisions to Client Tools"
    # Rights
    $readOnly = [System.Security.AccessControl.FileSystemRights]"ReadAndExecute"
    #$readWrite = [System.Security.AccessControl.FileSystemRights]"Modify"
    # Inheritance
    $inheritanceFlag = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
    # Propagation
    $propagationFlag = [System.Security.AccessControl.PropagationFlags]::None
    # User
    #$userRW = New-Object System.Security.Principal.NTAccount($groupNameRW)
    $userR = New-Object System.Security.Principal.NTAccount("vagrant")
    # Type
    $type = [System.Security.AccessControl.AccessControlType]::Allow
    
    $accessControlEntryDefault = New-Object System.Security.AccessControl.FileSystemAccessRule @("Domain Users", $readOnly, $inheritanceFlag, $propagationFlag, $type)
    $accessControlEntryX = New-Object System.Security.AccessControl.FileSystemAccessRule @($userR, $readOnly, $inheritanceFlag, $propagationFlag, $type)
    $ClientBin = "$Env:PS_HOME\bin\client\winx86"
    $objACL = Get-ACL $ClientBin
    $objACL.AddAccessRule($accessControlEntryX)
    Set-ACL $ClientBin $objACL
}

function execute_ca_setup() {
  # CA
  Write-Host "Setting Up Change Assistant"
  & $Env:PS_HOME\setup\PsCA\silentInstall.bat "$CA_PATH" $CA_TYPE $CA_BACKUP
}

function execute_ptf_setup() {
  # PTF
  Write-Host "Setting Up PeopleSoft Test Framework"
  & ${Env:PS_HOME}\setup\PsTestFramework\setup.bat
}

function execute_shortcut_setup() {
    # App Designer
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$Home\Desktop\AppDesigner.lnk")
    $Shortcut.TargetPath = "$Env:PS_HOME\bin\client\winx86\pside.exe"
    $Shortcut.Save()
    # Data Mover
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$Home\Desktop\DataMover.lnk")
    $Shortcut.TargetPath = "$Env:PS_HOME\bin\client\winx86\psdmt.exe"
    $Shortcut.Save()
    # Config Manager
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$Home\Desktop\ConfigManager.lnk")
    $Shortcut.TargetPath = "$Env:PS_HOME\bin\client\winx86\pscfg.exe"
    $Shortcut.Save()
    # SQL Developer
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$Home\Desktop\SQLDeveloper.lnk")
    $Shortcut.TargetPath = "C:\psft\db\oracle-server\12.1.0.2\sqldeveloper\sqldeveloper.exe"
    $Shortcut.Save()    
}

function execute_browser_setup {
    # Set Homepage
    $path = 'HKCU:\Software\Microsoft\Internet Explorer\Main\'
    $name = 'start page'
    $value = 'http://localhost:8000/ps/signon.html'
    Set-Itemproperty -Path $path -Name $name -Value $value
}

#-----------------------------------------------------------[Execution]-----------------------------------------------------------

if ($SECURITY  -eq 'true') {. execute_security_setup}
if ($CA_SETUP  -eq 'true') {. execute_ca_setup}
if ($PTF_SETUP -eq 'true') {. execute_ptf_setup}
if ($SHORTCUTS -eq 'true') {. execute_shortcut_setup}
if ($BROWSER   -eq 'true') {. execute_browser_setup}