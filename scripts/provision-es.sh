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
# set -u          # Treat unset variables as an error
set -o pipefail # Prevent errors in a pipeline from being masked
IFS=$'\n\t'     # Set the internal field separator to a tab and newline

###############
#  Variables  #
###############

export DEBUG=true

readonly TMPDIR="$(mktemp -d)"
readonly SCRIPT_PATH="$( cd "$( dirname "$0" )" && pwd )"
readonly PYTHON_HOME="${SCRIPT_PATH}/python"
readonly PATH="${PYTHON_HOME}:${PATH}"
readonly LIBPATH="/lib:/usr/lib:${LIBPATH}:${PYTHON_HOME}/lib"
readonly SHLIB_PATH="${PYTHON_HOME}/lib:${SHLIB_PATH}"
readonly LD_LIBRARY_PATH="${PYTHON_HOME}/lib:${LD_LIBRARY_PATH}"
readonly PYTHON_SCRIPTS_HOME="${SCRIPT_PATH}/scripts"
readonly PYTHONPATH=".:${PYTHON_SCRIPTS_HOME}:${PYTHON_SCRIPTS_HOME}/platform:${PYTHON_SCRIPTS_HOME}/manage:${PYTHON_SCRIPTS_HOME}/administer"

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

function deploy_es(){
  local begin=$(date +%s)
  echoinfo "Deploying Elasticsearch and Kibana"

  if [[ -n ${DEBUG+x} ]]; then
    cd "${PYTHON_SCRIPTS_HOME}" && python -W ignore psftutils.py --op=escfg
  else 
    cd "${PYTHON_SCRIPTS_HOME}" && python -W ignore psftutils.py --op=escfg > /dev/null 2>&1
  fi
  
  local end=$(date +%s)
  local tottime="$((end - begin))"
  timings[deploy_es]=$tottime
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

deploy_es

display_timings_summary