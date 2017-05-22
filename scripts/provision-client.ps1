﻿#Requires -Version 5

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

#-----------------------------------------------------------[Functions]-----------------------------------------------------------

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

#-----------------------------------------------------------[Execution]-----------------------------------------------------------

if ($CA_SETUP  -eq 'true') {. execute_ca_setup}
if ($PTF_SETUP -eq 'true') {. execute_ptf_setup}