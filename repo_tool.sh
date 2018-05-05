#!/bin/bash
# Description: simple tools to help working with submodules
# Author: Patrice Lachance
# Version: 1.0
##############################################################################



# logging function
_log() {
  echo $*
}



# execute & log function
_exec_log() {
  _log - exec: $*
  $*
}



# usage function
usage() {
  cat <<-EOT

  usage: $(basename $0) <option>

  where option is:
    update_submodules:   recursively update submodules

	EOT
  exit 1
}



# sync all local submodules with upstream
update_submodules() {
  _log BEGIN: update submodules
  # from: https://stackoverflow.com/a/19029685
  _exec_log git submodule update --init --recursive
  _exec_log git submodule foreach --recursive git fetch
  _exec_log git submodule foreach --recursive git pull --ff-only origin master
  # or git submodule foreach --recursive git merge origin master
  _log END: update submodules
}



# sync remote repositories from local
push_upstream() {
  _log BEGIN: pushing upstream
  _exec_log git push origin master
  _log END: pushing upstream
}



## Main logic
[ $# -lt 1 ] && usage
case $1 in
  update_submodules)
	  update_submodules
	  shift
	  ;;
  sync_all)
	  update_submodules
	  push_upstream
	  shift
	  ;;
  *)
	  ;;
esac



# Default exit status
exit 0
