#!/usr/bin/env bash
# shellcheck disable=2059,2154,2034,2155,2046
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

# shellcheck disable=2086
: ${MOS_USERNAME?"MOS_USERNAME must be specified in config.rb"}
# shellcheck disable=2086
: ${MOS_PASSWORD:?"MOS_PASSWORD must be specified in config.rb"}
# shellcheck disable=2086
: ${PATCH_ID:?"PATCH_ID must be specified in config.rb"}

#export DEBUG=true

readonly TMPDIR="$(mktemp -d)"
readonly COOKIE_FILE="${TMPDIR}/$$.cookies"
readonly AUTH_LOGFILE="${TMPDIR}/auth-wgetlog-$(date +%m-%d-%y-%H:%M).log"
readonly SEARCH_LOGFILE="${TMPDIR}/search-wgetlog-$(date +%m-%d-%y-%H:%M).log"
readonly DOWNLOAD_LOGFILE="${TMPDIR}/download-aria2log-$(date +%m-%d-%y-%H:%M).log"
readonly AUTH_OUTPUT="${TMPDIR}/auth_output"
readonly PATCH_SEARCH_OUTPUT="${TMPDIR}/patch_search_output"
readonly PATCH_FILE_LIST="${TMPDIR}/file_list"
readonly PUPPET_HOME="/etc/puppet"

declare -a additional_packages=("vim-enhanced" "htop" "jq")
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

function update_packages() {
  local begin=$(date +%s)
  echoinfo "Updating installed packages"
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
  wget --secure-protocol=TLSv1 \
    --save-cookies="${COOKIE_FILE}" \
    --keep-session-cookies \
    --no-check-certificate \
    --post-data="$AUTH_DATA" \
    --user="$MOS_USERNAME" \
    --password="$MOS_PASSWORD" \
    "https://updates.oracle.com/Orion/SimpleSearch/switch_to_saved_searches" \
    --output-document="${AUTH_OUTPUT}" \
    --output-file="${AUTH_LOGFILE}"
}

function download_search_results() {
  echodebug "Downloading search page results for ${PATCH_ID}"
  # plat_lang 226P = Linux x86_64
  # plat_lang 233P = Windows x86_64
  wget --secure-protocol=TLSv1 \
    --no-check-certificate \
    --load-cookies="${COOKIE_FILE}" \
    --output-document="${PATCH_SEARCH_OUTPUT}" \
    --output-file="${SEARCH_LOGFILE}" \
    "https://updates.oracle.com/Orion/SimpleSearch/process_form?search_type=patch&patch_number=${PATCH_ID}&plat_lang=226P"
}

function extract_download_links() {
  echodebug "Extracting download links"
  grep "btn_Download" "${PATCH_SEARCH_OUTPUT}" | \
    egrep ".*" | \
    sed 's/ //g' | \
    sed "s/.*href=\"//g" | \
    sed "s/\".*//g" \
    > "${PATCH_FILE_LIST}"
}

function download_patch_files() {
  # TODO - only download files if they don't already exist
  # TODO - create a subdirectory based on the patch ID for the files
  local begin=$(date +%s)
  create_authorization_cookie
  download_search_results
  extract_download_links
  echoinfo "Downloading patch files"
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
    #--log-level="notice"
  local end=$(date +%s)
  local tottime="$((end - begin))"
  timings[download_patch_files]=$tottime
}

function unpack_setup_scripts() {
  #TODO Test to see if the setup scripts have already been unpacked
  local begin=$(date +%s)
  echoinfo "Unpacking DPK setup scripts"
  unzip -u "${DPK_INSTALL}/*_1of*.zip" -d "${DPK_INSTALL}" > /dev/null 2>&1
  local end=$(date +%s)
  local tottime="$((end - begin))"
  timings[unpack_setup_scripts]=$tottime
}

function copy_customizations_file() {
  echoinfo "Copying customizations file"
  # TODO - validate the customizations file has been created
  if [[ -n ${DEBUG+x} ]]; then
    sudo cp -fv /vagrant/config/psft_customizations.yaml /etc/puppet/data/psft_customizations.yaml
  else
    sudo cp -f /vagrant/config/psft_customizations.yaml /etc/puppet/data/psft_customizations.yaml
  fi
}

function execute_psft_dpk_setup() {
  local begin=$(date +%s)
  echoinfo "Setting file execution attribute on psft-dpk-setup.sh"
  chmod +x "${DPK_INSTALL}/setup/psft-dpk-setup.sh"
  echoinfo "Executing DPK setup script"
  if [[ -n ${DEBUG+x} ]]; then
    sudo "${DPK_INSTALL}/setup/psft-dpk-setup.sh" \
      --dpk_src_dir="${DPK_INSTALL}" \
      --silent \
      --no_env_setup
  else
    sudo "${DPK_INSTALL}/setup/psft-dpk-setup.sh" \
      --dpk_src_dir="${DPK_INSTALL}" \
      --silent \
      --no_env_setup > /dev/null 2>&1
  fi
  local end=$(date +%s)
  local tottime="$((end - begin))"
  timings[execute_psft_dpk_setup]=$tottime
}

function execute_puppet_apply() {
  # TODO - possibly break this out into a separate provisioning script
  #        that gets applied every 'vagrant up'
  local begin=$(date +%s)
  echoinfo "Applying Puppet manifests"
  if [[ -n ${DEBUG+x} ]]; then
    sudo puppet apply --verbose "${PUPPET_HOME}/manifests/site.pp"
  else
    sudo puppet apply "${PUPPET_HOME}/manifests/site.pp" > /dev/null 2>&1
  fi
  local end=$(date +%s)
  local tottime="$((end - begin))"
  timings[execute_puppet_apply]=$tottime
}

function fix_init_script() {
  # For some reason the psft-db init script fails upon subsequent
  # reboots of the VM due to the LD_LIBRARY_PATH variable not being
  # available.  Since this works on prior versions of RHEL/OEL, I
  # can only assume it's due to a difference in the way that
  # systemd manages legacy init scripts.
  echoinfo "Applying fix for psft-db init script"
  sudo sed -i '/^LD_LIBRARY_PATH/s/^/export /' /etc/init.d/psft-db
  sudo systemctl daemon-reload
}

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

update_packages
install_additional_packages

download_patch_files
unpack_setup_scripts

execute_psft_dpk_setup

copy_customizations_file
execute_puppet_apply
fix_init_script

display_timings_summary
