#!/bin/bash
# Description: Check SSL Certificate
# Author: Patrice Lachance
# Source: https://serverfault.com/a/661982/413091
##############################################################################

# Loading common helper functions
. ./common.sh



# How to use this tool
usage() {
  cat << EOT

  $(basename $0) <FQDN> { <PORT> }

  PORT is optional, defaulting to 443 if not specified

EOT
  exit 1
}



# Let's go!
[ $# -ne 1 ] && usage

FQDN=$1
PORT=${2:-443}

# Checking SSL Certificate
_log "##############################################################################"
_log "# Checking SSL Certificate for '$FQDN:$PORT'"
echo | openssl s_client -showcerts -servername $FQDN -connect $FQDN:$PORT 2>/dev/null | openssl x509 -inform pem -noout -text
_log "# Done"
_log "##############################################################################"

