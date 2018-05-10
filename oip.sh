#!/bin/bash
# Description: simple tools to help working with submodules
# Author: Patrice Lachance
# Version: 1.0
##############################################################################


#TODO: load variables from env
HTTP_PROXY="http://webproxy.prd.lab-nxtit.priv:3128"
HTTPS_PROXY="http://webproxy.prd.lab-nxtit.priv:3128"
WILDCARD_DOMAIN="apps.ocp.lab-nxtit.com"



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
    sync_push:           recursively sync modules and push upstream
    sync_templates:      generate templates and push them to OCP
    deploy_guides:       deploy various app guides on OCP

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
  #_exec_log git submodule foreach --recursive git merge origin master
  _log END: update submodules
}



# sync remote repositories from local
push_upstream() {
  _log BEGIN: pushing upstream
  _exec_log git push origin master
  _log END: pushing upstream
}



# deploy learning guides
deploy_guides() {
  _log BEGIN: deploy guides
  _exec_log oc new-project oip-labs
  _log " - processing guide 'cloud-native'"

  # From: https://github.com/openshift-labs/starter-guides
  _exec_log oc new-app osevg/workshopper:latest --name=starter-guide \
    -e WORKSHOPS_URLS="https://raw.githubusercontent.com/openshift-labs/starter-guides/master/_workshops/training.yml" \
    -e CONSOLE_ADDRESS=$(oc whoami --show-server | sed 's~https://~~') -e ROUTER_ADDRESS=$WILDCARD_DOMAIN \
    -e DOCS_URL=docs.openshift.org
  _exec_log oc env dc/starter-guide http_proxy=$HTTP_PROXY
  _exec_log oc env dc/starter-guide https_proxy=$HTTPS_PROXY
  _exec_log oc expose svc/starter-guide

  # From: https://github.com/openshift-labs/cloud-native-guides
  _exec_log oc new-app osevg/workshopper:latest --name=cloud-native \
    -e WORKSHOPS_URLS="https://raw.githubusercontent.com/openshift-labs/cloud-native-guides/ocp-3.9/_cloud-native-roadshow.yml"
  _exec_log oc env dc/cloud-native http_proxy=$HTTP_PROXY
  _exec_log oc env dc/cloud-native https_proxy=$HTTPS_PROXY
  _exec_log oc expose svc/cloud-native

  # From: https://github.com/openshift-labs/rhsummit18-cloudnative-guides
  _exec_log oc new-app osevg/workshopper:latest --name=rhs18-cloud-native \
    -e WORKSHOPS_URLS="https://raw.githubusercontent.com/openshift-labs/rhsummit18-cloudnative-guides/master/_rhsummit18.yml" \
    -e JAVA_APP=false 
  _exec_log oc env dc/rhs18-cloud-native http_proxy=$HTTP_PROXY
  _exec_log oc env dc/rhs18-cloud-native https_proxy=$HTTPS_PROXY
  _exec_log oc expose svc/rhs18-cloud-native

  _log " - processing guide 'devops-oab'"
  # From: https://github.com/openshift-labs/devops-oab-guides
  _exec_log oc new-app osevg/workshopper:latest --name=devops-oab \
    -e WORKSHOPS_URLS="https://raw.githubusercontent.com/openshift-labs/devops-oab-guides/master/_summit-devops-lab.yml"
  _exec_log oc env dc/devops-oab http_proxy=$HTTP_PROXY
  _exec_log oc env dc/devops-oab https_proxy=$HTTPS_PROXY
  _exec_log oc expose svc/devops-oab

  _log " - processing guide 'custom-svc-broker'"
  # From: https://github.com/openshift-labs/custom-service-broker-workshop
  _exec_log oc new-app osevg/workshopper:latest --name=custom-svc-broker \
    -e CONTENT_URL_PREFIX="https://raw.githubusercontent.com/openshift-labs/custom-service-broker-workshop/master/" \
    -e WORKSHOPS_URLS="https://raw.githubusercontent.com/openshift-labs/custom-service-broker-workshop/master/_workshop.yml"
  _exec_log oc env dc/custom-svc-broker http_proxy=$HTTP_PROXY
  _exec_log oc env dc/custom-svc-broker https_proxy=$HTTPS_PROXY
  _exec_log oc expose svc/custom-svc-broker

  _log END: deploy guides
}



# generate templates and upload them to OCP
sync_templates() {
  _log BEGIN: sync templates

  #TODO: handle docker image missing

  # Generate templates definitions form source
  _exec_log docker run --rm -v $(pwd):/data itisopen/oip-init:nightly generate

  # upload them to OCP, replacing existing ones, if any
  for tmpl in $(ls -d generated/templates/* | grep -v vars); do
    [ -d "$tmpl" -a -f "$tmpl/template.yaml" ] || continue
    tmpl_name=$(basename -- $tmpl)
    #TODO: avoid polling 
    if oc -n openshift get template $tmpl_name >/dev/null 2>&1; then
      _log "deleting existing template '$tmpl_name'"
      oc -n openshift delete template $tmpl_name
    else
      _log "template '$tmpl_name' not found"
    fi
    _exec_log oc -n openshift create -f $tmpl/template.yaml
  done

  _log END: sync templates
}



## Main logic
[ $# -lt 1 ] && usage
case $1 in
  update_submodules)
	  update_submodules
	  shift
	  ;;
  sync_repos)
	  _log "Pulling base project's from upstream"
	  _exec_log git pull
	  update_submodules
	  push_upstream
	  shift
	  ;;
  sync_templates)
	  sync_templates
	  shift
	  ;;
  deploy_guides)
	  deploy_guides
	  shift
	  ;;
  *)
	  ;;
esac



# Default exit status
exit 0
