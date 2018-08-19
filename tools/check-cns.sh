#!/usr/bin/env bash
# Description: Check Cloud Native Storage status using
#   GlusterFS & Heketi
# Author: Patrice Lachance
# Source: https://access.redhat.com/solutions/3397561
##############################################################################

# Required variables
PROJECT=${1:-glusterfs}



# Loading common helper functions
. ./common.sh



# Checking GlusterFS status
_log "##############################################################################"
_log "# Checking GlusterFS status by inspecting pods in project '$PROJECT'"
for pod in $(oc get pods -o=custom-columns=NAME:.metadata.name --no-headers | grep glusterfs); do
    _log "-> checking 'glusterd' status..."
    _exec_log oc -n $PROJECT exec $pod -- systemctl status glusterd;
    _log "------------------------------------------------------------------------------"
    _log "-> checking gluster peers' status..."
    _exec_log oc -n $PROJECT exec $pod -- gluster peer status; 
    _log "------------------------------------------------------------------------------"
    _log "-> checking gluster volumes status..."
    oc -n $PROJECT exec $pod -- gluster vol status all;
done
_log "# Done"
_log "##############################################################################"



# Checking Heketi
_log 
_log
_log "##############################################################################"
_log "Checking Heketi status using heketi pod(s) in project '$PROJECT'"
for pod in $(oc get pods -o=custom-columns=NAME:.metadata.name --no-headers | grep heketi | grep -v deploy); do
    _log "-> checking heketi volume list..."
    _exec_log oc -n $PROJECT exec $pod -- sh -c 'heketi-cli --user admin --secret "$HEKETI_ADMIN_KEY" volume list'
    _log "------------------------------------------------------------------------------"
    _log "-> checking heketi topology info..."
    _exec_log oc -n $PROJECT exec $pod -- sh -c 'heketi-cli --user admin --secret "$HEKETI_ADMIN_KEY" topology info'
done
_log "# Done"
_log "##############################################################################"
