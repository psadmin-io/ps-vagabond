#!/usr/bin/env bash
# shellcheck disable=2059,2154,2034,2155,2046,2086
#===============================================================================
# vim: softtabstop=2 shiftwidth=2 expandtab fenc=utf-8 spelllang=en ft=sh
#===============================================================================
#
#          FILE: preloadcache.sh
#
#         USAGE: ./preloadcache.sh
#
#   DESCRIPTION: Build application cache for the PeopleSoft Image.
#
#===============================================================================

set -e          # Exit immediately on error
set -u          # Treat unset variables as an error
set -o pipefail # Prevent errors in a pipeline from being masked
IFS=$'\n\t'     # Set the internal field separator to a tab and newline

###############
#  Variables  #
###############

# export DEBUG=true
DPK_HOME="/opt/oracle/psft/dpk/puppet"
PUPPET_BIN="/opt/puppetlabs/puppet/bin"
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

function download_manifests() {
  local begin=$(date +%s)
  echoinfo "Copying Manifests"

  if [[ -n ${DEBUG+x} ]]; then
    sudo cp /vagrant/scripts/loadcache.pp $DPK_HOME/production/manifests/loadcache.pp
    sudo cp /vagrant/scripts/fixdpkbug.pp $DPK_HOME/production/manifests/fixdpkbug.pp
  else
    cd $DPK_HOME/production
    sudo cp /vagrant/scripts/loadcache.pp $DPK_HOME/production/manifests/loadcache.pp > /dev/null 2>&1
    sudo cp /vagrant/scripts/fixdpkbug.pp $DPK_HOME/production/manifests/fixdpkbug.pp > /dev/null 2>&1
  fi

  local end=$(date +%s)
  local tottime="$((end - begin))"
  timings[download_manifests]=$tottime
}

function fix_dpk_bug(){
  local begin=$(date +%s)
  echoinfo "Fix DPK App Engine Bug"

  if [[ -n ${DEBUG+x} ]]; then
    sudo $PUPPET_BIN/puppet apply $DPK_HOME/production/manifests/fixdpkbug.pp --confdir $DPK_HOME -d
  else 
    sudo $PUPPET_BIN/puppet apply $DPK_HOME/production/manifests/fixdpkbug.pp --confdir $DPK_HOME -d > /dev/null 2>&1
  fi
  
  local end=$(date +%s)
  local tottime="$((end - begin))"
  timings[fix_dpk_bug]=$tottime
}

function load_cache(){
  local begin=$(date +%s)
  echoinfo "Pre-load Application Cache"

  if [[ -n ${DEBUG+x} ]]; then
    sudo $PUPPET_BIN/puppet apply $DPK_HOME/production/manifests/loadcache.pp --confdir $DPK_HOME -d
  else 
    sudo $PUPPET_BIN/puppet apply $DPK_HOME/production/manifests/loadcache.pp --confdir $DPK_HOME -d > /dev/null 2>&1
  fi
  
  local end=$(date +%s)
  local tottime="$((end - begin))"
  timings[load_cache]=$tottime
}

##########
#  Main  #
##########

download_manifests
fix_dpk_bug
load_cache

display_timings_summary