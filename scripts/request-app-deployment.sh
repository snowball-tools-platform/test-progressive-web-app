#!/bin/bash

set -e

RECORD_FILE=tmp.rf.$$
CONFIG_FILE=`mktemp`

rcd_name=$(jq -r '.name' package.json | sed 's/null//' | sed 's/^@//')
rcd_app_version=$(jq -r '.version' package.json | sed 's/null//')

cat <<EOF > "$CONFIG_FILE"
services:
  cns:
    restEndpoint: '${CERC_REGISTRY_REST_ENDPOINT:-http://console.laconic.com:1317}'
    gqlEndpoint: '${CERC_REGISTRY_GQL_ENDPOINT:-http://console.laconic.com:9473/api}'
    chainId: ${CERC_REGISTRY_CHAIN_ID:-laconic_9000-1}
    gas: 950000
    fees: 200000aphoton
EOF

if [ -z "$CERC_REGISTRY_APP_CRN" ]; then
  authority=$(echo "$rcd_name" | cut -d'/' -f1 | sed 's/@//')
  app=$(echo "$rcd_name" | cut -d'/' -f2-)
  CERC_REGISTRY_APP_CRN="crn://$authority/applications/$app"
fi

APP_RECORD=$(laconic -c $CONFIG_FILE cns name resolve "$CERC_REGISTRY_APP_CRN" | jq '.[0]')
if [ -z "$APP_RECORD" ] || [ "null" == "$APP_RECORD" ]; then
  echo "No record found for $CERC_REGISTRY_APP_CRN."
  exit 1
fi

cat <<EOF | sed '/.*: ""$/d' > "$RECORD_FILE"
record:
  type: ApplicationDeploymentRequest
  version: 1.0.0
  name: "$rcd_name@$rcd_app_version"
  application: "$CERC_REGISTRY_APP_CRN@$rcd_app_version"
  dns: "$CERC_REGISTRY_DEPLOYMENT_SHORT_HOSTNAME"
  deployment: "$CERC_REGISTRY_DEPLOYMENT_CRN"
  config:
    env:
      CERC_WEBAPP_DEBUG: "$rcd_app_version"
  meta:
    note: "Added by CI @ `date`"
    repository: "`git remote get-url origin`"
    repository_ref: "${GITHUB_SHA:-`git log -1 --format="%H"`}"
EOF

cat $RECORD_FILE
RECORD_ID=$(laconic -c $CONFIG_FILE cns record publish --filename $RECORD_FILE --user-key "${CERC_REGISTRY_USER_KEY}" --bond-id ${CERC_REGISTRY_BOND_ID} | jq -r '.id')
echo $RECORD_ID

rm -f $RECORD_FILE $CONFIG_FILE
