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
  if (-Not (Test-Path C:\ProgramData\chocolatey\bin\wget.exe)) {
    Write-Host "Installing wget"
    if ($DEBUG -eq "true") {
      choco install wget -y
    } else {
      choco install wget -y 2>&1 | out-null
    }
  }
  If (Test-Path Alias:wget) { Remove-Item Alias:wget 2>&1 | out-null }
  If (Test-Path Alias:wget) { Remove-Item Alias:wget 2>&1 | out-null }
  if (-Not (Test-Path C:\ProgramData\chocolatey\bin\jq.exe)) {
    Write-Host "Installing jq"
    if ($DEBUG -eq "true") {
      choco install jq -y
    } else {
      choco install jq -y 2>&1 | out-null
    }
  }
  if (-Not (Test-Path C:\ProgramData\chocolatey\bin\aria2c.exe)) {
    Write-Host "Installing aria2"
    if ($DEBUG -eq "true") {
      choco install aria2 -y
    } else {
      choco install aria2 -y 2>&1 | out-null
    }
  }
}

function create_authorization_cookie {
  if (Test-Path $COOKIE_FILE) { Remove-Item $COOKIE_FILE }
  $MOS_TOKEN = ([System.Uri](((Invoke-WebRequest -Uri "https://updates.oracle.com/Orion/SimpleSearch" `
                                                -UserAgent "Mozilla/5.0" `
                                                -UseBasicParsing `
                                                -MaximumRedirection 0 `
                                                -ErrorAction SilentlyContinue |
              Select-Object -ExpandProperty RawContent).toString() -Split  '[\r\n]' |
              Select-String "Location").ToString() -Split  ' ')[1] -Split '=')[1]

  $AUTH_DATA="ssousername=${MOS_USERNAME}&password=${MOS_PASSWORD}&site2pstoretoken=${MOS_TOKEN}"
  $AuthURL = "https://login.oracle.com/sso/auth"

  Invoke-WebRequest -Uri $AuthURL `
                    -UserAgent "Mozilla/5.0" `
                    -SessionVariable MOSSession `
                    -Method Post `
                    -UseBasicParsing `
                    -Body $AUTH_DATA | Out-Null

  wget --secure-protocol=TLSv1 `
       --save-cookies="${COOKIE_FILE}" `
       --keep-session-cookies `
       --no-check-certificate `
       --post-data="${AUTH_DATA}" `
       --user="${MOS_USERNAME}" `
       --password="${MOS_PASSWORD}" `
       "https://updates.oracle.com/Orion/SimpleSearch/switch_to_saved_searches"  `
       --output-document="${AUTH_OUTPUT}" `
       --output-file="${AUTH_LOGFILE}"
}

function download_search_results {
  Write-Host "Downloading search page results for ${PATCH_ID}"
  $SEARCH_LOGFILE = Invoke-WebRequest -uri "https://updates.oracle.com/Orion/SimpleSearch/process_form?search_type=patch&patch_number=${PATCH_ID}&plat_lang=233P" `
                                      -UserAgent "Mozilla/5.0" `
                                      -WebSession $MOSSession `
                                      -UseBasicParsing
}

function extract_download_links {
  if (test-path $PATCH_FILE_LIST) {remove-item $PATCH_FILE_LIST}
  (($SEARCH_LOGFILE.RawContent -Split '\r\n' | Select-String 'id="btn_Download"') -Split '"' | Select-String 'updates.oracle.com') | set-content $PATCH_FILE_LIST
}

function download_patch_files {
  $status = get-content $VAGABOND_STATUS | convertfrom-json
  if ( $status.download_patch_files -eq "false") {
    Write-Host "Downloading patch files"
    $begin=$(get-date)
    . create_authorization_cookie

    If ($($MOSSession.Cookies.GetCookieHeader("https://login.oracle.com") | Select-String "ORA_UCM_INFO=").Matches.Success) {
      . download_search_results
      . extract_download_links

      if ($DEBUG -eq "true") {
        aria2c --input-file $PATCH_FILE_LIST `
          --dir $DPK_INSTALL `
          --load-cookies "${env:TEMP}/mos.cookies" `
          --max-connection-per-server=5 `
          --max-concurrent-downloads=5 `
          --file-allocation=none `
          --log="${env:TEMP}/dlLog.log" `
          --log-level="info" `
          --user-agent="Mozilla/5.0"
      } else {
        aria2c --input-file $PATCH_FILE_LIST `
          --dir $DPK_INSTALL `
          --load-cookies "${env:TEMP}/mos.cookies" `
          --max-connection-per-server=5 `
          --max-concurrent-downloads=5 `
          --file-allocation=none `
          --log="${env:TEMP}/dlLog.log" `
          --log-level="info" `
          --user-agent="Mozilla/5.0" 2>&1 | out-null
      }
    }
	#Confirm zip files exist in download location
	if (-Not (test-path $DPK_INSTALL/*.zip)){
	Write-Host "#####################################################################################" -foregroundcolor yellow
    Write-Host "ERROR!!!!! NO ZIP FILES FOUND IN $DPK_INSTALL directory. `n Confirm PATCH_ID is correct and check %TEMP%\dlLog.LOG" -foregroundcolor yellow
	Write-Host "#####################################################################################" -foregroundcolor yellow
    exit 1
    }
	
    record_step_success "download_patch_files"
    # local end=$(date +%s)
    # local tottime="$((end - begin))"
    # timings[download_patch_files]=$tottime
  } else {
    Write-Host "Patch files already downloaded"
  }
}

function unpack_setup_scripts() {
  $status = get-content $VAGABOND_STATUS | convertfrom-json
  if ( $status.unpack_setup_scripts -eq "false") {
    # local begin=$(date +%s)
    Write-Host "Unpacking DPK setup scripts"
    if ($DEBUG -eq "true") {
      get-childitem "${DPK_INSTALL}/*.zip" | % { Expand-Archive $_ -DestinationPath ${DPK_INSTALL} -Force}
    } else {
      get-childitem "${DPK_INSTALL}/*.zip" | % { Expand-Archive $_ -DestinationPath ${DPK_INSTALL} -Force}  2>&1 | out-null
    }
	
	if (-Not (test-path $DPK_INSTALL/setup/*)){
	Write-Host "#####################################################################################" -foregroundcolor yellow
    Write-Host "ERROR!!!!! NO  FILES FOUND IN $DPK_INSTALL/setup directory. `n Check logs in %TEMP%\" -foregroundcolor yellow
	Write-Host "#####################################################################################" -foregroundcolor yellow
    exit 1
    }
	
    record_step_success "unpack_setup_scripts"
    # local end=$(date +%s)
    # local tottime="$((end - begin))"
    # timings[unpack_setup_scripts]=$tottime
  } else {
    Write-Host "Setup scripts already unpacked"
  }
}

# function display_timings_summary {
#   $divider='============================================================'
#   $total_duration = 0

#   for duration in "${timings[@]}"; do
#     total_duration=$((duration + total_duration))
#   done

#   Write-Host "TASK`t`tDURATION"
#   Write-Host "${divider}"
#   for key in "${!timings[@]}"; do
#     local converted_timing=$(date -u -d @${timings[$key]} +"%T")
#     printf "$format" "$key" "${converted_timing}"
#   done
#   Write-Host "%$width.${width}s\n" "$divider"
#   Write-Host "$format" "TOTAL TIME:" $(date -u -d @${total_duration} +"%T")
#   Write-Host "`n"
# }

function cleanup_before_exit {
  if ($DEBUG -eq "true") {
    Write-Host "Temporary files and logs can be found in ${env:TEMP}"
  } else {
    Write-Host "Cleaning up temporary files"
    Remove-Item $env:TEMP -Recurse -Force 2>&1 | out-null
  }

  # $fqdn = facter fqdn
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

# . display_timings_summary

# Issue 27 - commenting out for now
# . cleanup_before_exit
