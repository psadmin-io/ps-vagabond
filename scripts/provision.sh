#!/usr/bin/env bash
# shellcheck disable=2059,2154,2034,2155,2046,2086
#===============================================================================
# vim: softtabstop=2 shiftwidth=2 expandtab fenc=utf-8 spelllang=en ft=sh
#===============================================================================
#
#          FILE: provision.sh
#
#         USAGE: ./provision.sh
#
#   DESCRIPTION: Provisioning script to download the dpk and run delivered setup
#                script.
#
#===============================================================================

set -e          # Exit immediately on error
set -u          # Treat unset variables as an error
set -o pipefail # Prevent errors in a pipeline from being masked
IFS=$'\n\t'     # Set the internal field separator to a tab and newline

###############
#  Variables  #
###############

: ${MOS_USERNAME:?"MOS_USERNAME must be specified in config.rb"}
: ${MOS_PASSWORD:?"MOS_PASSWORD must be specified in config.rb"}
: ${PATCH_ID:?"PATCH_ID must be specified in config.rb"}

export DEBUG=true

readonly TMPDIR="$(mktemp -d)"
readonly COOKIE_FILE="${TMPDIR}/$$.cookies"
readonly AUTH_LOGFILE="${TMPDIR}/auth-wgetlog-$(date +%m-%d-%y-%H:%M).log"
readonly SEARCH_LOGFILE="${TMPDIR}/search-wgetlog-$(date +%m-%d-%y-%H:%M).log"
readonly DOWNLOAD_LOGFILE="${TMPDIR}/download-aria2log-$(date +%m-%d-%y-%H:%M).log"
readonly AUTH_OUTPUT="${TMPDIR}/auth_output"
readonly PATCH_SEARCH_OUTPUT="${TMPDIR}/patch_search_output"
readonly PATCH_FILE_LIST="${TMPDIR}/file_list"
readonly PSFT_BASE_DIR="/opt/oracle/psft"
readonly VAGABOND_STATUS="${DPK_INSTALL}/vagabond.json"
readonly CUSTOMIZATION_FILE="/vagrant/config/psft_customizations.yaml"
readonly PSFT_CFG_DIR="${PSFT_CFG_DIR}"
# readonly EXTRAS_URL="https://packagecloud.io/install/repositories/jrbing/ps-extras/script.rpm.sh"

declare -a additional_packages=("/lib64/libnsl.so.1" "ncurses-compat-libs" "glibc-devel" "oracle-epel-release-el8" "vim-enhanced" "htop" "jq" "python3-pip" "python3-pyyaml" "python3-requests" "unzip" "samba" "samba-client" "aria2" "attr" "libgcc.i686" "glibc.i686" "net-tools")
declare -A timings

###############
#  Functions  #
###############

function echoinfo() {
  local GC="\033[1;32m"
  local EC="\033[0m"
  printf "${GC} ☆  INFO${EC}: %s${GC}\n" "$@";
}

function echodebug() {
  local BC="\033[1;34m"
  local EC="\033[0m"
  local GC="\033[1;32m"
  if [[ -n ${DEBUG+x} ]]; then
    printf "${BC} ★  DEBUG${EC}: %s${GC}\n" "$@";
  fi
}

function echoerror() {
  local RC="\033[1;31m"
  local EC="\033[0m"
  printf "${RC} ✖  ERROR${EC}: %s\n" "$@" 1>&2;
}

function echobanner() {
  local BC="\033[1;34m"
  local EC="\033[0m"
  local GC="\033[1;32m"
  
  printf "\n\n"
  printf "${BC}                                      dP                               dP ${GC}\n"
  printf "${BC}                                      88                               88 ${GC}\n"
  printf "${BC}  dP   .dP .d8888b. .d8888b. .d8888b. 88d888b. .d8888b. 88d888b. .d888b88 ${GC}\n"
  printf "${BC}  88   d8' 88'  \`88 88'  \`88 88'  \`88 88'  \`88 88'  \`88 88'  \`88 88'  \`88 ${GC}\n"
  printf "${BC}  88 .88'  88.  .88 88.  .88 88.  .88 88.  .88 88.  .88 88    88 88.  .88 ${GC}\n"
  printf "${BC}  8888P'   \`88888P8 \`8888P88 \`88888P8 88Y8888' \`88888P' dP    dP \`88888P8 ${GC}\n"
  printf "${BC}                         .88 ${GC}\n"
  printf "${BC}                     d8888P ${GC}\n"
  printf "\n\n"
}

function echomotd(){

  echo "Welcome to Vagabond - PeopleSoft Images on Vagrant

  List Domains:         psa list
  Domain Status:        psa status [type] [domain]
  Stop Domains:         psa stop [type] [domain]
  Start Domains:        psa start [type] [domain]
  Restart Domains:      psa restart [type] [domain]
  Bounce Domains:       psa bounce [type] [domain]
    Bounce will: stop, clear cache and IPC, reload config, start

  Domain Types: web, app, prcs, all
  
  Examples:
    psa list
    psa status app
    psa bounce
    psa restart web
    psa stop app APPDOM
    psa restart prcs 

" | sudo tee /etc/motd > /dev/null 2>&1
}

function install_prereqs() {
  check_dpk_install_dir
  check_vagabond_status
  # apply_slow_dns_fix # Removed for OEL 8
  update_packages
  install_additional_packages
  start_smb
  set_permissivie_selinux
}

# function apply_slow_dns_fix() {
#   echodebug "Applying slow DNS fix (single-request-reopen)"
#   ## https://access.redhat.com/site/solutions/58625 (subscription required)
#   # http://www.linuxquestions.org/questions/showthread.php?p=4399340#post4399340
#   # add 'single-request-reopen' so it is included when /etc/resolv.conf is generated
#   if [[ -n ${DEBUG+x} ]]; then
#     echo 'RES_OPTIONS="single-request-reopen"' >> /etc/sysconfig/network
#     systemctl restart network
#   else
#     echo 'RES_OPTIONS="single-request-reopen"' >> /etc/sysconfig/network > /dev/null 2>&1
#     systemctl restart network > /dev/null 2>&1
#   fi
# }

function start_smb() {
  echodebug "Starting Samba"
  if [[ -n ${DEBUG+x} ]]; then
    systemctl start smb.service
  else
    systemctl start smb.service > /dev/null 2>&1
  fi
}

function set_permissivie_selinux() {
  echodebug "Set SELinux to Permissive"
  if [[ -n ${DEBUG+x} ]]; then
    echo 0 | sudo tee /sys/fs/selinux/enforce
  else
    echo 0 | sudo tee /sys/fs/selinux/enforce > /dev/null 2>&1
  fi
}


function check_dpk_install_dir() {
  if [[ ! -d "${DPK_INSTALL}" ]]; then
    echodebug "DPK installation directory ${DPK_INSTALL} does not exist"
    mkdir -p "${DPK_INSTALL}"
	chmod 777 "${DPK_INSTALL}"
  else
    echodebug "Found DPK installation directory ${DPK_INSTALL}"
  fi
}

function check_vagabond_status() {
  if [[ ! -e "${VAGABOND_STATUS}" ]]; then
    echodebug "Vagabond status file ${VAGABOND_STATUS} does not exist"
    cp /vagrant/scripts/vagabond.json "${DPK_INSTALL}"
  else
    echodebug "Found Vagabond status file ${VAGABOND_STATUS}"
  fi
}

function record_step_success() {
  local step=$1
  local tempfile="$TMPDIR/vagabond_status_temp.json"
  echodebug "Recording success for ${step}"
  < "$VAGABOND_STATUS" jq ".$step = \"true\"" > "$tempfile" && mv "$tempfile" "$VAGABOND_STATUS"
}

function update_packages() {
  echoinfo "Updating installed packages"
  local begin=$(date +%s)
  if [[ -n ${DEBUG+x} ]]; then
    sudo yum update -y
  else
    sudo yum update -y > /dev/null 2>&1
  fi
  local end=$(date +%s)
  local tottime="$((end - begin))"
  timings[update_packages]=$tottime
}

function install_additional_packages() {
  local begin=$(date +%s)
  echoinfo "Installing additional packages"
  for package in "${additional_packages[@]}"; do
    if [[ -n ${DEBUG+x} ]]; then
      echodebug "Installing ${package}"
      sudo yum install -y "${package}"
    else
      sudo yum install -y "${package}" > /dev/null 2>&1
    fi
  done
  local end=$(date +%s)
  local tottime="$((end - begin))"
  timings[install_additional_packages]=$tottime
}

function create_authorization_cookie() {
  echodebug "Authenticating and generating cookie file"
  # shellcheck disable=2155
  local MOS_TOKEN="$(curl --silent --head https://updates.oracle.com/Orion/Services/download | grep Location | cut -d '=' -f 2|cut -d ' ' -f 1)"
  local AUTH_DATA="ssousername=$MOS_USERNAME&password=$MOS_PASSWORD&site2pstoretoken=$MOS_TOKEN"

  wget --secure-protocol=auto \
    --save-cookies="${COOKIE_FILE}" \
    --keep-session-cookies \
    --no-check-certificate \
    --post-data="$AUTH_DATA" \
    --user="$MOS_USERNAME" \
    --password="$MOS_PASSWORD" \
    "https://updates.oracle.com/Orion/Services/download" \
    --output-document="${AUTH_OUTPUT}" \
    --output-file="${AUTH_LOGFILE}"
}

function download_search_results() {
  echodebug "Downloading search page results for ${PATCH_ID}"
  # plat_lang 226P = Linux x86_64
  # plat_lang 233P = Windows x86_64

  wget --secure-protocol=auto \
    --no-check-certificate \
    --load-cookies="${COOKIE_FILE}" \
    --output-document="${PATCH_SEARCH_OUTPUT}" \
    --output-file="${SEARCH_LOGFILE}" \
    "https://updates.oracle.com/Orion/SimpleSearch/process_form?search_type=patch&patch_number=${PATCH_ID}&plat_lang=226P"
}

function extract_download_links() {
  echodebug "Extracting download links"
  grep "btn_Download" "${PATCH_SEARCH_OUTPUT}" | \
    grep -E ".*" | \
    sed 's/ //g' | \
    sed "s/.*href=\"//g" | \
    sed "s/\".*//g" \
    > "${PATCH_FILE_LIST}"
}

function download_patch_files() {
  if [[ $(jq --raw-output ".${FUNCNAME[0]}" < "$VAGABOND_STATUS") == "false" ]]; then
    echoinfo "Downloading patch files"
    local begin=$(date +%s)
    
    create_authorization_cookie
    download_search_results
    extract_download_links

    echodebug "Downloading .zip files for ${PATCH_ID}"
    aria2c \
      --input-file="${PATCH_FILE_LIST}" \
      --dir="${DPK_INSTALL}" \
      --load-cookies="${COOKIE_FILE}" \
      --user-agent="Mozilla/5.0" \
      --max-connection-per-server=5 \
      --max-concurrent-downloads=5 \
      --quiet=true \
      --file-allocation=none \
      --log="${DOWNLOAD_LOGFILE}" \
      --log-level="info"
      
    record_step_success "${FUNCNAME[0]}"
    local end=$(date +%s)
    local tottime="$((end - begin))"
    timings[download_patch_files]=$tottime
  else
    echoinfo "Patch files already downloaded"
  fi
}

function unpack_setup_scripts() {
  if [[ $(jq --raw-output ".${FUNCNAME[0]}" < "$VAGABOND_STATUS") == "false" ]]; then
    local begin=$(date +%s)
    echoinfo "Unpacking DPK setup scripts"
    if [[ -n ${DEBUG+x} ]]; then
      unzip -u "${DPK_INSTALL}/*_1of*.zip" -d "${DPK_INSTALL}"
    else
      unzip -u "${DPK_INSTALL}/*_1of*.zip" -d "${DPK_INSTALL}" > /dev/null 2>&1
    fi
    record_step_success "${FUNCNAME[0]}"
    local end=$(date +%s)
    local tottime="$((end - begin))"
    timings[unpack_setup_scripts]=$tottime
  else
    echoinfo "Setup scripts already unpacked"
  fi
}

function determine_tools_version() {
  TOOLS_VERSION=$(awk -F "=" '/version/ {print $2}' ${DPK_INSTALL}/setup/bs-manifest)
  TOOLS_MAJOR_VERSION=$(printf $TOOLS_VERSION | cut -f 1 -d '.')
  TOOLS_MINOR_VERSION=$(printf $TOOLS_VERSION | cut -f 2 -d '.')
  TOOLS_PATCH_VERSION=$(printf $TOOLS_VERSION | cut -f 3 -d '.')
  echodebug "Tools Version: ${TOOLS_VERSION}"
  echodebug "Tools Major Version: ${TOOLS_MAJOR_VERSION}"
  echodebug "Tools Minor Version: ${TOOLS_MINOR_VERSION}"
  echodebug "Tools Patch Version: ${TOOLS_PATCH_VERSION}"
}

function determine_puppet_home() {
  case ${TOOLS_MINOR_VERSION} in
    "55" | "56" | "57" | "58" )
        echoerror "Tools Version ${TOOLS_VERSION} is no longer supported. Use a previous release of ps-vagabond."
      ;;
    "59" | "60" )
        PUPPET_HOME="${PSFT_BASE_DIR}/dpk/puppet"
      ;;
    * )
        echoerror "Tools Version ${TOOLS_VERSION} is not yet supported."
      ;;
  esac
  echodebug "Puppet Home Directory: ${PUPPET_HOME}"
}

function copy_customizations_file() {
  echoinfo "Copying customizations file"
  if [[ -n ${DEBUG+x} ]]; then
    sudo cp -fv /vagrant/config/psft_customizations.yaml ${PUPPET_HOME}/data/psft_customizations.yaml
  else
    sudo cp -f /vagrant/config/psft_customizations.yaml ${PUPPET_HOME}/data/psft_customizations.yaml
  fi
}

function lookup_cust_value() {
  local value=$1
  < "${CUSTOMIZATION_FILE}" shyaml get-value $value
}

function generate_response_file() {
  echodebug "Generating response file"
  local begin=$(date +%s)
cat > "${DPK_INSTALL}/response.cfg" << EOF
psft_base_dir="${PSFT_BASE_DIR}"
install_type = PUM
env_type  = "fulltier"
db_type = DEMO
db_name = "PSFTDB"
db_service_name = "PSFTDB"
db_host = "localhost"
admin_pwd = "Passw0rd_"
connect_id = people
connect_pwd = "peop1e"
access_pwd  = "SYSADM"
opr_pwd = "PS"
domain_conn_pwd = "Passw0rd_"
weblogic_admin_pwd  = "Passw0rd#"
webprofile_user_pwd = "PTWEBSERVER"
gw_user_pwd = "password"
gw_keystore_pwd = "password"
user_home_dir = "/home"
psft_es_esadmin_pwd = "Passw0rd#"
psft_es_espeople_pwd = "peop1e"
EOF
  local end=$(date +%s)
  local tottime="$((end - begin))"
  timings[generate_response_file]=$tottime
}

function execute_puppet_apply() {
  local begin=$(date +%s)
  echoinfo "Applying Puppet manifests"
  case ${TOOLS_MINOR_VERSION} in
    "59" | "60" )
        if [[ -n ${DEBUG+x} ]]; then
          sudo puppet apply \
            --confdir="${PSFT_BASE_DIR}/dpk/puppet" \
            --verbose \
            "${PUPPET_HOME}/production/manifests/site.pp"
        else
          sudo puppet apply \
            --confdir="${PSFT_BASE_DIR}/dpk/puppet" \
            "${PUPPET_HOME}/production/manifests/site.pp" > /dev/null 2>&1
        fi
      ;;
    * )
        echoerror "Tools Version ${TOOLS_VERSION} is not yet supported."
      ;;
  esac
  local end=$(date +%s)
  local tottime="$((end - begin))"
  timings[execute_puppet_apply]=$tottime
}

function execute_pre_setup() {
  local begin=$(date +%s)
  echoinfo "Executing Pre setup script"
  if [[ -n ${DEBUG+x} ]]; then
    if [ ! -z "${PSFT_CFG_DIR}" ]; then
      echodebug "Pre making PS_CFG_HOME"
      sudo mkdir -pv "${PSFT_CFG_DIR}"
      sudo chmod -v 777 "${PSFT_CFG_DIR}"
    else
      echodebug 'Skipping pre make PS_CFG_HOME, PSFT_CFG_DIR not set.'
    fi
  else
    if [ -n "${PSFT_CFG_DIR}" ]; then
      sudo mkdir -p "${PSFT_CFG_DIR}" > /dev/null 2>&1
      sudo chmod 777 "${PSFT_CFG_DIR}" > /dev/null 2>&1
    fi
  fi
  local end=$(date +%s)
  local tottime="$((end - begin))"
  timings[execute_pre_setup]=$tottime
}

function execute_psft_dpk_setup() {
  local begin=$(date +%s)
  echodebug "Setting file execution attribute on psft-dpk-setup.sh"
  
  # This should already be executable, but just in case it's not
  if [[ ! -x "${DPK_INSTALL}/setup/psft-dpk-setup.sh" ]]; then
	chmod +x "${DPK_INSTALL}/setup/psft-dpk-setup.sh"
  fi  
  
  echoinfo "Executing DPK setup script"
  case ${TOOLS_MINOR_VERSION} in
    "59" | "60" )
        generate_response_file
        if [[ -n ${DEBUG+x} ]]; then
          sudo "${DPK_INSTALL}/setup/psft-dpk-setup.sh" \
            --dpk_src_dir="${DPK_INSTALL}" \
            --customization_file="${CUSTOMIZATION_FILE}" \
            --silent \
            --response_file "${DPK_INSTALL}/response.cfg"
        else
          sudo "${DPK_INSTALL}/setup/psft-dpk-setup.sh" \
            --dpk_src_dir="${DPK_INSTALL}" \
            --customization_file="${CUSTOMIZATION_FILE}" \
            --silent \
            --response_file "${DPK_INSTALL}/response.cfg" > /dev/null 2>&1
        fi
      ;;
    * )
        echoerror "Tools Version ${TOOLS_VERSION} is not supported."
      ;;
  esac
  local end=$(date +%s)
  local tottime="$((end - begin))"
  timings[execute_psft_dpk_setup]=$tottime
}

function install_psadmin_plus(){
  local begin=$(date +%s)
  echoinfo "Install psadmin_plus"


  case ${TOOLS_MINOR_VERSION} in
    "59" | "60" )
      if [[ -n ${DEBUG+x} ]]; then
        curl --insecure https://rubygems.org/downloads/psadmin_plus-2.0.5.gem -o psadmin_plus.gem > /dev/null 2>&1
        sudo $PSFT_BASE_DIR/psft_puppet_agent/bin/gem install --local psadmin_plus.gem
      else 
        curl --insecure https://rubygems.org/downloads/psadmin_plus-2.0.5.gem -o psadmin_plus.gem > /dev/null 2>&1
        sudo $PSFT_BASE_DIR/psft_puppet_agent/bin/gem install --local psadmin_plus.gem > /dev/null 2>&1
      fi
      echo "PATH=$PATH:$PSFT_BASE_DIR/psft_puppet_agent/bin" | tee -a ~/.bash_profile > /dev/null 2>&1
      ;;
    * )
      echo "Tools Version not supported"
      ;;
  esac

  local end=$(date +%s)
  local tottime="$((end - begin))"
  timings[install_psadmin_plus]=$tottime
}

# function open_firewall_ports(){
#   local begin=$(date +%s)
#   echoinfo "Open Firewall Ports"

#   if [[ -n ${DEBUG+x} ]]; then
#     sudo firewall-cmd --permanent --add-port=8000/tcp
#     sudo firewall-cmd --permanent --add-port=1521:1522/tcp
#     sudo firewall-cmd --reload
#   else
#     sudo firewall-cmd --permanent --add-port=8000/tcp > /dev/null 2>&1
#     sudo firewall-cmd --permanent --add-port=1521:1522/tcp > /dev/null 2>&1
#     sudo firewall-cmd --reload > /dev/null 2>&1
#   fi

#   local end=$(date +%s)
#   local tottime="$((end - begin))"
#   timings[open_firewall_ports]=$tottime
# }

function display_timings_summary() {
  local divider='=============================='
  divider=$divider$divider
  local header="\n %-28s %s\n"
  local format=" %-28s %s\n"
  local width=40
  local total_duration=0

  for duration in "${timings[@]}"; do
    total_duration=$((duration + total_duration))
  done

  printf "$header" "TASK" "DURATION"
  printf "%$width.${width}s\n" "$divider"
  for key in "${!timings[@]}"; do
    local converted_timing=$(date -u -d @${timings[$key]} +"%T")
    printf "$format" "$key" "${converted_timing}"
  done
  printf "%$width.${width}s\n" "$divider"
  printf "$format" "TOTAL TIME:" $(date -u -d @${total_duration} +"%T")
  printf "\n"
}


function cleanup_before_exit () {
  if [[ -n ${DEBUG+x} ]]; then
    echodebug "Temporary files and logs can be found in ${TMPDIR}"
  else
    echoinfo "Cleaning up temporary files"
    rm -rf "${TMPDIR}"
  fi
}
trap cleanup_before_exit EXIT

##########
#  Main  #
##########

echobanner

# Prerequisites
echomotd
install_prereqs

# Downloading and unpacking patch files
download_patch_files
unpack_setup_scripts

# Determine the tools version and configure appropriately
determine_tools_version
determine_puppet_home

# Running the setup script
execute_pre_setup
execute_psft_dpk_setup

# Postrequisite fixes
install_psadmin_plus

# Oracle Vagrant boxes ship with firewalld disabled - leaving in case this chagnes
# open_firewall_ports 

# Summary information
display_timings_summary
