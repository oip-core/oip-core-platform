#!/usr/bin/env bash
#
# Description: journald cleanup script
# Author: Patrice Lachance
# Source: https://unix.stackexchange.com/a/194058/159958
##############################################################################

# Loading common helper functions
. ./common.sh



# How to use this tool
usage() {
  cat << EOT

  $(basename $0) { -s <target log size> | -t <keep n days> }

  use either '-s' or '-t' form

EOT
  exit 1
}



# Let's go!

while getopts ":s:t:" opt; do
  case ${opt} in
    s )
        PARAM="--vacuum-size=${OPTARG}"
        ;;
    t )
        PARAM="--vacuum-time=${OPTARG}"
        ;;
    * ) usage
        ;;
  esac
done
shift "$(($OPTIND -1))"

[ "x$PARAM" != "x" ] || usage

# Cleaning journald logs
_log "##############################################################################"
_log "# Cleaning up journald"
_exec_log journalctl $PARAM
_log "# Done"
_log "##############################################################################"

