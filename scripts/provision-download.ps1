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
  [String]$MOS_USERNAME = $env:MOS_USERNAME,
  [String]$MOS_PASSWORD = $env:MOS_PASSWORD,
  [String]$DPK_INSTALL  = $env:DPK_INSTALL
)


#---------------------------------------------------------[Initialization]--------------------------------------------------------

# Valid values: "Stop", "Inquire", "Continue", "Suspend", "SilentlyContinue"
$ErrorActionPreference = "Stop"
$DebugPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

#------------------------------------------------------------[Variables]----------------------------------------------------------

If ( ${MOS_USERNAME} -eq '' ) { Write-Host "MOS_USERNAME must be specified in config.rb or `$env:MOS_USERNAME" }
If ( ${MOS_PASSWORD} -eq '' ) { Write-Host "MOS_PASSWORD must be specified in config.rb or `$env:MOS_PASSWORD" }
If ( ${PATCH_ID} -eq '' ) { Write-Host "PATCH_ID must be specified in config.rb" }

$DEBUG = "false"

$PATCH_FILE_LIST  = "${env:TEMP}\file_list"
$COOKIE_FILE      = "${env:TEMP}\mos.cookies"
$AUTH_OUTPUT      = "${env:TEMP}\auth_output"
$AUTH_LOGFILE     = "${env:TEMP}\auth.log"
$PUPPET_HOME      = "C:\ProgramData\PuppetLabs\puppet\etc"
$VAGABOND_STATUS  = "${DPK_INSTALL}\vagabond.json"

#-----------------------------------------------------------[Functions]-----------------------------------------------------------

#Function Log-Info {
    #Param (
        #[Parameter(Mandatory=$true)][string]$Message
    #)
    #Process {
        #Write-Host "INFO: $Message  " -Fore DarkYellow
    #}
#}

#Function Log-Error {
    #Param (
        #[Parameter(Mandatory=$true)][string]$Message,
        #[Parameter(Mandatory=$false)][boolean]$ExitGracefully
    #)
    #Process {
        #Write-Warning -Message "Error: An error has occurred [$ErrorDesc]."
        #If ($ExitGracefully -eq $True){
            #Break
        #}
    #}
#}

#Function Example-Function{
    #Param()
    #Begin {
        #Log-Info -Message "Entering..."
    #}
    #Process {
        #Try {
            #Log-Info -Message "Executing..."
        #}
        #Catch {
            #Log-Error -Message $_.Exception -ExitGracefully $True
            #Break
        #}
    #}
    #End {
        #If($?) {
            #Log-Info -Message "Completed Successfully."
        #}
    #}
#}

function check_dpk_install_dir {
  if (-Not (test-path $DPK_INSTALL)) {
    Write-Host "DPK installation directory ${DPK_INSTALL} does not exist"
    mkdir $DPK_INSTALL
  } else {
    Write-Host "Found DPK installation directory ${DPK_INSTALL}"
  }
}

function check_vagabond_status {
  if (-Not (Test-Path "${VAGABOND_STATUS}" )) {
    Write-Host "Vagabond status file ${VAGABOND_STATUS} does not exist"
    if ($DEBUG -eq "true") {
      Copy-Item C:\vagrant\scripts\vagabond.json $DPK_INSTALL -Verbose
    } else {
      Copy-Item C:\vagrant\scripts\vagabond.json $DPK_INSTALL
    }
  } else {
    Write-Host "Found Vagabond status file ${VAGABOND_STATUS}"
  }
}

function record_step_success($step) {
  Write-Host "Recording success for ${step}"
  $status = get-content $VAGABOND_STATUS | convertfrom-json
  $status.$step = "true"
  convertto-json $status | set-content $VAGABOND_STATUS
}

function install_additional_packages {

  if (-Not (Test-Path C:\ProgramData\chocolatey\bin)) {
    Write-Host "Installing Chocolatey Package Manager"
    if ($DEBUG -eq "true") {
      (Invoke-Expression ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')))
    } else {
      (Invoke-Expression ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))) 2>&1 | out-null
    }
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
  }

  if (-Not (Test-Path C:\ProgramData\chocolatey\bin\jq.exe)) {
    Write-Host "Installing jq"
    if ($DEBUG -eq "true") {
      choco install jq -y
    } else {
      choco install jq -y 2>&1 | out-null
    }
  }
}


# Functions from Andy Dorfman
# https://gist.githubusercontent.com/umaritimus/fcca0abad0c85d29e0df729e6ae57229

Function Get-MyOracleSupportSession {
  [CmdletBinding(DefaultParameterSetName='Anonymous')]

  Param (
      [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'Credential')][System.Management.Automation.PSCredential]${Credential},
      [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'Password')][String]${Username},
      [Parameter(Position = 0, Mandatory = $True, ParameterSetName = 'Password')][String]${Password}
  )

  Begin {
      ${ProgressPreference} = 'SilentlyContinue'
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12

      If (${PsCmdlet}.ParameterSetName -ne "Anonymous") {
          If (${PsCmdlet}.ParameterSetName -eq "Credential" -and ${Credential} -ne [System.Management.Automation.PSCredential]::Empty) {
              ${Username} = ${Credential}.UserName
              ${Password} = ${Credential}.GetNetworkCredential().Password
          }
      }

      ${RequestBody} = "ssousername=$([System.Net.WebUtility]::UrlEncode(${Username}))&password=$([System.Net.WebUtility]::UrlEncode(${Password}))"
  }

  Process {
      # Discover the URL of the authenticator
      ${Location} = [System.Uri](
          (
              (
                  Invoke-WebRequest `
                      -Uri "https://updates.oracle.com/Orion/Services/metadata?table=aru_platforms" `
                      -UserAgent "Mozilla/5.0" `
                      -UseBasicParsing `
                      -MaximumRedirection 0 `
                      -ErrorAction SilentlyContinue `
                  | Select-Object -ExpandProperty RawContent
              ).toString() -Split '[\r\n]' | Select-String "Location"
          ).ToString() -Split ' '
      )[1]

      # Acquire MOS session
      Invoke-WebRequest `
          -Uri ${Location}.AbsoluteUri `
          -UserAgent "Mozilla/5.0" `
          -UseBasicParsing `
          -SessionVariable MyOracleSupportSession `
          -Method Post `
          -Body ${RequestBody} `
      | Out-Null

      # IF ORA_UCM_INFO cookie is present => authentication succeeded
      If ($(${MyOracleSupportSession}.Cookies.GetCookieHeader("$(${Location}.Scheme)://$($Location.Host)") | Select-String "ORA_UCM_INFO=").Matches.Success) {
          Return ${MyOracleSupportSession}
      } Else {
          Throw "Authentication request failed for ${UserName}"
      }
  }

}

Function Import-MyOracleSupportPatches {
  [CmdletBinding()]

  Param(
      [Parameter(Mandatory = $True)][Microsoft.PowerShell.Commands.WebRequestSession] ${MyOracleSupportSession},
      [Parameter(Mandatory = $True)][String] ${PatchNumber},
      [Parameter(Mandatory = $False)][String] ${Platform} = '233',
      [Parameter(Mandatory = $False)][String] ${PatchPassword} = ${Null},
      [Parameter(Mandatory = $False)][String] ${PatchDownloadLocation} = ${Env:TEMP},
      [Parameter(Mandatory = $False)][Switch] ${Force}
  )

  Begin {
      ${ProgressPreference} = 'SilentlyContinue'
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12

      # Check if the mos session is valid
      If (-Not $(${MyOracleSupportSession}.Cookies.GetCookieHeader('https://login.oracle.com') | Select-String "ORA_UCM_INFO=").Matches.Success) {
          Throw "MyOracleSupport authenticated session couldn't be acquired"
      }
  }

  Process {
      # Get the Patch page for parsing
      $PatchPage = Invoke-WebRequest `
          -Uri "https://updates.oracle.com/Orion/PatchDetails/process_form?patch_num=${PatchNumber}&plat_lang=${Platform}P&plat_lang=2000P&patch_password=${PatchPassword}&" `
          -UserAgent "Mozilla/5.0" `
          -WebSession $MyOracleSupportSession `
          -UseBasicParsing

      # Get the patch description
      # TODO: add patch description to patch metadata
      ${PatchDescription} = (
          ($PatchPage.RawContent -Split '\n' | Select-String -Pattern 'Description\<\/font\>' -Context 2,3) -Replace '\r\n' `
          | Select-String -Pattern '<font class=OraDataText>(.*)</font>' -AllMatches `
          | ForEach-Object { ${_}.Matches} `
          | ForEach-Object { ${_}.Groups[1].Value }
      ).Trim()

      Write-Verbose "Patch Description - ${PatchDescription}"

      $PatchFiles = (($PatchPage.RawContent -Split '\r\n' | select-String 'id="btn_Download"') -Split '"' | Select-String 'updates.oracle.com')

      If (${PatchFiles}.Length -eq 0) {
          ${PatchFiles} = ($PatchPage.RawContent.Split([Environment]::NewLine) | select-String -Pattern 'href=\"\b(https://updates.oracle.com/.*)\b\&\"\x3E' -AllMatches) | ForEach-Object { ${_}.Matches.Groups[1].Value }
      }

      # Create download location if doesn't exist
      If (-not (Test-Path ${PatchDownloadLocation} -ErrorAction SilentlyContinue)) {
          New-Item -Path "${PatchDownloadLocation}" -ItemType Directory -Force | Out-Null
      }

      # Generate Array of patch_file locations
      ${ImportedPatches} = New-Object System.Collections.ArrayList

      # Process Patch file downloads
      # TODO: make it parallel
      For (${i} = 0; ${i} -lt ${PatchFiles}.Count; ${i}++) {
          ${PatchFile} = ${PatchFiles}[${i}]

          ${Source} = [System.Uri]${PatchFile}.ToString()
          ${Destination} = "${PatchDownloadLocation}\$($source.Segments[-1])"

          ${ImportedPatches}.Add(${Destination}) | Out-Null

          # If the patch file already exists, skip it; otherwise, if doesn't yet exists or -Force flag is set, then download it
          # TODO: do SHA-256 check
          If (${Force} -or (-not $( Try { Test-Path -Path "${Destination}" -ErrorAction SilentlyContinue } Catch { $False } )) ) {
              Write-Verbose "[Task] Download ${Destination}"
              Invoke-WebRequest `
                  -Uri ${Source} `
                  -UserAgent "Mozilla/5.0" `
                  -WebSession ${MyOracleSupportSession} `
                  -UseBasicParsing `
                  -TimeoutSec 600 `
                  -Method Get `
                  -OutFile ${Destination}
          } Else {
              Write-Verbose "[Skip] ${Destination} already exists."
          }

      }

      Return ${ImportedPatches}
  }
}

function download_patch_files {
  $status = get-content $VAGABOND_STATUS | convertfrom-json
  if ( $status.download_patch_files -eq "false") {
    Write-Host "Downloading patch files"
    $begin=$(get-date)

    $PASSWORD = ConvertTo-SecureString $MOS_PASSWORD -AsPlainText -Force
    $MOS_CREDENTIAL = New-Object System.Management.Automation.PSCredential ($MOS_USERNAME, $PASSWORD)
    if ($DEBUG -eq "true") {
      $MOS_SESSION = Get-MyOracleSupportSession -Credential $MOS_CREDENTIAL -Verbose
    } else {
      $MOS_SESSION = Get-MyOracleSupportSession -Credential $MOS_CREDENTIAL
    }
    
    $PATCH_LIST = Import-MyOracleSupportPatches -MyOracleSupportSession $MOS_SESSION -PatchNumber $PATCH_ID -PatchDownloadLocation $DPK_INSTALL

    #Confirm zip files exist in download location
    if (-Not (test-path $DPK_INSTALL/*.zip)){
      Write-Host "#####################################################################################" -foregroundcolor yellow
      Write-Host "ERROR!!!!! NO ZIP FILES FOUND IN $DPK_INSTALL directory. `n Confirm PATCH_ID is correct and check DPK_INSTALL for log files" -foregroundcolor yellow
      Write-Host "#####################################################################################" -foregroundcolor yellow
    exit 1
    }
	
    record_step_success "download_patch_files"
  } else {
    Write-Host "Patch files already downloaded"
  }
}

function unpack_setup_scripts() {
  $status = get-content $VAGABOND_STATUS | convertfrom-json
  if ( $status.unpack_setup_scripts -eq "false") {
    Write-Host "Unpacking DPK setup scripts"
    if ($DEBUG -eq "true") {
      get-childitem "${DPK_INSTALL}/*.zip" | % { Expand-Archive $_ -DestinationPath ${DPK_INSTALL} -Force}
      remove-item *UPD*.zip
    } else {
      get-childitem "${DPK_INSTALL}/*.zip" | % { Expand-Archive $_ -DestinationPath ${DPK_INSTALL} -Force}  2>&1 | out-null
      remove-item *UPD*.zip 2>&1 | out-null
    }
	
	  if (-Not (test-path $DPK_INSTALL/setup/*)){
      Write-Host "#####################################################################################" -foregroundcolor yellow
      Write-Host "ERROR!!!!! NO  FILES FOUND IN $DPK_INSTALL/setup directory. `n Check logs in %TEMP%\" -foregroundcolor yellow
      Write-Host "#####################################################################################" -foregroundcolor yellow
      exit 1
    }
	
    record_step_success "unpack_setup_scripts"
  } else {
    Write-Host "Setup scripts already unpacked"
  }
}

function cleanup_before_exit {
  if ($DEBUG -eq "true") {
    Write-Host "Temporary files and logs can be found in ${env:TEMP}"
  } else {
    Write-Host "Cleaning up temporary files"
    Remove-Item $env:TEMP -Recurse -ErrorAction SilentlyContinue -Force 2>&1 | out-null
  }
}

#-----------------------------------------------------------[Execution]-----------------------------------------------------------

##########
#  Main  #
##########

. check_dpk_install_dir
. check_vagabond_status

. install_additional_packages

. download_patch_files
. unpack_setup_scripts

. cleanup_before_exit
