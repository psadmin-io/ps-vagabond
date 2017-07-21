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
  [String]$PTF_SETUP    = $env:PTF_SETUP,
  [String]$IE_HOMEPAGE  = $env:IE_HOMEPAGE
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
$CFG_MGR   = 'true'

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
    
    $accessControlEntry = New-Object System.Security.AccessControl.FileSystemAccessRule @($userR, $readOnly, $inheritanceFlag, $propagationFlag, $type)
    $ClientBin = "$Env:PS_HOME\bin\client\winx86"
    $objACL = Get-ACL $ClientBin
    $objACL.AddAccessRule($accessControlEntry)
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

function config_manager_setup () {
    Write-Host "Importing Config Manager Setup"

    & regedit /s c:\vagrant\config\client.reg

#     $base           = hiera peoplesoft_base | Resolve-Path
#     $db_name        = hiera db_name
#     $db_user        = hiera db_user
#     $db_connect_id  = hiera db_connect_id
#     $db_connect_pwd = hiera db_connect_pwd
#     $ps_home        = hiera ps_home_location | Resolve-Path

#     $cfg_file = @"
# [PSTOOLS]
# Start=REG_SZ=APPLICATION_DESIGNER
# Language=REG_SZ=
# WindowWidth=REG_DWORD=640
# WindowHeight=REG_DWORD=448
# PanelSize=REG_SZ=CLIP
# StartNavigator=REG_SZ=
# PanelInNavigator=REG_SZ=
# HighlightPopupMenuFlds=REG_SZ=
# ShowDBName=REG_DWORD=0
# MaxWorkInstances=REG_DWORD=250
# TenKeyMode=REG_SZ=NO
# DbFlags=REG_DWORD=0
# Business Interlink Driver Directory=REG_SZ=
# JDeveloper Directory=REG_SZ=
# JDeveloper Launch Mapper CPath=REG_SZ=
# FontFace=REG_SZ=MS Sans Serif
# FontPoints=REG_DWORD=8
# [Startup]
# DBType=REG_SZ=ORACLE
# ServerName=REG_SZ=
# DBName=REG_SZ=${db_name}
# DBChange=REG_SZ=YES
# UserId=REG_SZ=${db_user}
# ConnectId=REG_SZ=${db_connect_id}
# ClientConnectPswd=REG_SZ=${db_connect_pwd}
# [Cache Settings]
# CacheBaseDir=REG_SZ=C:\PS
# [Trace]
# TraceSql=REG_DWORD=0
# TracePC=REG_DWORD=0
# TraceAE=REG_DWORD=0
# AETFileSize=REG_DWORD=500
# TraceFile=REG_SZ=
# [PSIDE\PCDebugger]
# PSDBGSRV Listener Port=REG_DWORD=9500

# [Crystal]
# Trace=REG_SZ=
# CrystalDir=REG_SZ=
# TraceFile=REG_SZ=
# CustomReports=REG_SZ=

# [RemoteCall]
# RCCBL Timeout=REG_DWORD=50
# RCCBL Redirect=REG_DWORD=0
# RCCBL Animate=REG_DWORD=0
# Show Window=REG_DWORD=0

# [Setup]
# GroupName=REG_SZ=
# Icons=REG_DWORD=0
# MfCobolDir=REG_SZ=

# [PSIDE]
# "@
    # $file = New-Item -type file "${base}\pscfg.cfg" -force
    # $cfg_file | out-file $file -Encoding ascii
    # Write-Host "pscfg.cfg: `n ${cfg_file}"
    # set-location "${ps_home}\bin\client\winx86"
    # $pscfg = "${ps_home}\bin\client\winx86\pscfg.exe"
    # Start-Process -FilePath "$git" -ArgumentList "clone https://github.com/psadmin-io/psadmin-plus.git $psa"
    # Start-Process -FilePath $pscfg -ArgumentList "-import:c:\vagrant\config\pscfg.cfg -encrypt:${db_connect_pwd}"

}

function execute_browser_setup {
    # Set Homepage
    $path = 'HKCU:\Software\Microsoft\Internet Explorer\Main\'
    $name = 'start page'
    $value = "${IE_HOMEPAGE}"
    Set-Itemproperty -Path $path -Name $name -Value $value
}

function execute_profile_setup {
    #New-Item -path $profile -type file –force
    $psa = "c:/vagrant/scripts/psadmin-plus/PSAdminPlus.ps1"
    $new_profile = "new-alias psa $psa"
    $new_profile | Set-Content $profile
}

#-----------------------------------------------------------[Execution]-----------------------------------------------------------

if ($SECURITY  -eq 'true') {. execute_security_setup}
if ($CA_SETUP  -eq 'true') {. execute_ca_setup}
if ($PTF_SETUP -eq 'true') {. execute_ptf_setup}
if ($SHORTCUTS -eq 'true') {. execute_shortcut_setup}
if ($BROWSER   -eq 'true') {. execute_browser_setup}
if ($CFG_MGR   -eq 'true') {. config_manager_setup}
if ('true'     -eq 'true') {. execute_profile_setup}
