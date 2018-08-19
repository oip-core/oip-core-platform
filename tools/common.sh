#!/usr/bin/env bash
# Description: Common functions
# Author: Patrice Lachance
##############################################################################

VERBOSE=${VERBOSE:-true}

# Logging function
_log() {
  [ "x$VERBOSE" != "x" ] && echo "$@"
}

# Error function
_err() {
  _log "$@"
  exit 1
}

# Execute command and log
_exec_log() {
  _log "$ CMD=$@"
  "$@" || _log "ERROR while executing command"
}
