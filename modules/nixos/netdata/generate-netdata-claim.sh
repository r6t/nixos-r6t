#!/usr/bin/env bash

NETDATA_TOKEN=$(cat /run/secrets/netdata/cloud/claim_token)
#NETDATA_ROOMS=$(cat /run/secrets/netdata/cloud/claim_rooms)

mkdir -p /var/lib/netdata/cloud.d
touch /var/lib/netdata/cloud.d/token
echo "$NETDATA_TOKEN" > /var/lib/netdata/cloud.d/token
