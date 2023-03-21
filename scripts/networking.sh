#!/usr/bin/env bash
# shellcheck disable=2059,2154,2034,2155,2046,2086
#===============================================================================
# vim: softtabstop=2 shiftwidth=2 expandtab fenc=utf-8 spelllang=en ft=sh
#===============================================================================
#
#          FILE: networking.sh
#
#         USAGE: ./networking.sh
#
#   DESCRIPTION: Configure bridge networking on the vagrant box
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

function set_gateway() {
  nmcli connection modify "System eth0" ipv4.never-default yes 
  nmcli connection modify "System eth0" ipv4.gateway $GATEWAY 
  nmcli networking off 
  nmcli networking on
}

function set_hostname_resolver() {
  echodebug "Setting domain to ${DOMAIN}"
  echo search $DOMAIN | tee -a /etc/resolv.conf
}

function set_bridged_hostname() {
  nameserver=$(grep search /etc/resolv.conf | tail -n1 | gawk -F' ' '{ print $2 }')
  echo $IP_ADDRESS $(hostname) $(hostname).${nameserver} | tee -a /etc/hosts > /dev/null 2>&1
  echoinfo
  echoinfo
  echoinfo "===> Add '${IP_ADDRESS} $(hostname) $(hostname).${nameserver}' to your hosts file"
  echoinfo
  echoinfo
}

function set_private_hostname() {
  privateip=$(ifconfig eth0 | grep 'inet ' | cut -d' ' -f10)
  echo $privateip $(hostname) $(hostname).$DOMAIN | tee -a /etc/hosts > /dev/null 2>&1
  echoinfo
  echoinfo
  echoinfo "===> Add '${privateip} $(hostname) $(hostname).$DOMAIN' to your hosts file"
  echoinfo
  echoinfo
}

##########
#  Main  #
##########

set_hostname_resolver

case ${NETWORK_SETTINGS} in
    "bridged" )
      set_gateway
      set_bridged_hostname
      ;;
    "private" | "hostonly" )
      set_private_hostname
      ;;
esac

