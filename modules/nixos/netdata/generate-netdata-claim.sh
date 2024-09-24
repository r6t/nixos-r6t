#!/usr/bin/env bash

NETDATA_TOKEN=$(cat /run/secrets/netdata/cloud/claim_token)
#NETDATA_ROOMS=$(cat /run/secrets/netdata/cloud/claim_rooms)

cat <<EOF > /var/lib/netdata/cloud.d/token
$NETDATA_TOKEN
EOF
