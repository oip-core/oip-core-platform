#!/usr/bin/env bash
#
# Description: tool to create a Persistent Volume Claim
# Author: Patrice Lachance
##############################################################################

# Loading common helper functions
. ./common.sh



# How to use this tool
usage() {
  cat << EOT

  $(basename $0) -n <name> { -c <class> | -s <size> | -p <volume> }

  Mandatory parameters:

    -n     Name of the persistent volume claim

  Optional parameters:
    -c     Name of storage class to create the volume from
           Defaults to "default"
    -m     Access mode. Valid values are ReadWriteOnce, ReadWriteMany, ReadOnlyMany
           Defaults to "ReadWriteOnce"
    -p     Request the claim to be mapped to an existing volume
           If not specified, a new volume will be created
    -s     Size of the volume to be created
           Defaults to "1Gi"

EOT
  exit 1
}



# Check for mandatory parameters
check_mandatory_params() {
  for var in CLASS NAME SIZE; do
    
    if [ "x$(eval echo \$$var)" == "x" ]; then
      _log "\nERROR: parameter '$var' is mandatory" && usage
    fi
  done
}



# Check if storage class supports write many
check_class_rwx() {
  PROVISIONER=$(oc get storageclass $CLASS -o jsonpath='{.provisioner}')
  case $PROVISIONER in
    kubernetes.io/glusterfs)
      ;;
    *)
      _err "Provisioner '$PROVISIONER' doesn't support mode 'ReadWriteMany'"
      ;;
  esac
}



# Check if paramaters are valid
check_params() {
  # Existing PVC with that name?
  $(oc -n $PROJECT get pvc $NAME > /dev/null 2>&1 )
  [ $? -eq 0 ] && _err "PVC '$NAME' already exists in project '$PROJECT'"
  
  # Storage class
  if ! oc get storageclass $CLASS > /dev/null 2>&1; then
    _err "storage class '$CLASS' not found"
  fi 

  # Access mode
  case $ACCESS_MODE in
    RWO)
      ACCESS_MODE="ReadWriteOnce"
      ;;
    RWX)
      ACCESS_MODE="ReadWriteMany"
      ;;
    ROX)
      ACCESS_MODE="ReadOnlyMany"
      ;;
    ReadWriteOnce|ReadWriteMany|ReadOnlyMany)
      ;;
    *)
      _err "Access mode '$ACCESS_MODE' not supported"
  esac

  [ "$ACCESS_MODE" == "ReadWriteMany" ] && check_class_rwx

  # Size units
  UNIT=$(echo $SIZE | sed -s 's/[0-9]\+//')
  case $UNIT in
    Mi|Gi)
      ;;
    *)
      _err "Size unit '$UNIT' not supported"
  esac

  # Requested an existing PV
  if [ -n "$PV" ]; then
    # does it exists?
    #TODO: find how to implement it because regular
    # users are not allowed to list PV with default role
    #TODO: can they be queried by project?

    # is it already mapped to a claim
    return
  fi
}



# 
# Let's go!


# Making sure user is connected
$(oc whoami -t > /dev/null 2>&1 )
[ $? -ne 0 ] && _err "You must have a valid token"

# Setting default values
ACCESS_MODE="ReadWriteOnce"
CLASS="$(oc get storageclass | grep default | awk '{print $1}')"
PROJECT="$(oc project -q)"
SIZE="1Gi"

#VERBOSE=

# Collect command line parameters
while getopts ":c:m:n:p:P:s:" opt; do
  case ${opt} in
    c )
        CLASS="${OPTARG}"
        ;;
    m )
        ACCESS_MODE="${OPTARG}"
        ;;
    n )
        NAME="${OPTARG}"
        ;;
    p )
        PV="${OPTARG}"
        VOLUME_NAME="volumeName: '$PV'"
        ;;
    P )
        PROJECT="${OPTARG}"
        ;;
    s )
        SIZE="${OPTARG}"
        ;;
    * ) usage
        ;;
  esac
done
shift "$(($OPTIND -1))"

check_mandatory_params
check_params

# Cleaning journald logs
_log "##############################################################################"
_log "# Creating PVC '$NAME' of size '$SIZE' of type '$CLASS"
cat <<EOT | oc create -n $PROJECT -f -
apiVersion: "v1"
kind: "PersistentVolumeClaim"
metadata:
  name: "$NAME"
spec:
  accessModes:
    - "$ACCESS_MODE"
  resources:
    requests:
      storage: "$SIZE"
  storageClassName: "$CLASS"
  $VOLUME_NAME
EOT
_log "# Done"
_log "##############################################################################"

