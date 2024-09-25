#!/usr/bin/env bash

NETDATA_TOKEN=$(cat /run/secrets/netdata/cloud/claim_token)
#NETDATA_ROOMS=$(cat /run/secrets/netdata/cloud/claim_rooms)

echo "$NETDATA_TOKEN" > /var/lib/netdata/cloud.d/token
