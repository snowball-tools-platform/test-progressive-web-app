#!/bin/bash

set -e

RECORD_FILE=tmp.rf.$$
CONFIG_FILE=`mktemp`

CERC_APP_TYPE=${CERC_APP_TYPE:-"webapp"}
CERC_REPO_TAG=${CERC_REPO_TAG:-${GITHUB_SHA:-main}}

rcd_name=$(jq -r '.name' package.json | sed 's/null//')
rcd_desc=$(jq -r '.description' package.json | sed 's/null//')
rcd_repository=$(jq -r '.repository' package.json | sed 's/null//')
rcd_homepage=$(jq -r '.homepage' package.json | sed 's/null//')
rcd_license=$(jq -r '.license' package.json | sed 's/null//')
rcd_author=$(jq -r '.license' package.json | sed 's/null//')
rcd_app_version=$(jq -r '.version' package.json | sed 's/null//')

cat <<EOF > "$CONFIG_FILE"
services:
  cns:
    restEndpoint: '${CERC_LACONIC_REST_ENDPOINT:-http://console.laconic.com:1317}'
    gqlEndpoint: '${CERC_LACONIC_GQL_ENDPOINT:-http://console.laconic.com:9473/api}'
    chainId: ${CERC_LACONIC_CHAIN_ID:-laconic_9000-1}
    gas: 350000
    fees: 200000aphoton
EOF

next_ver=$(laconic -c $CONFIG_FILE cns record list --type ApplicationRecord --all --name "$rcd_name" 2>/dev/null | jq -r -s ".[] | sort_by(.createTime) | reverse | [ .[] | select(.bondId == \"$CERC_LACONIC_BOND_ID\") ] | .[0].attributes.version" | awk -F. -v OFS=. '{$NF += 1 ; print}')

if [ -z "$next_ver" ] || [ "1" == "$next_ver" ]; then
  next_ver=0.0.1
fi

cat <<EOF | sed '/.*: ""$/d' > "$RECORD_FILE"
record:
  type: ApplicationRecord
  version: ${next_ver}
  name: "$rcd_name"
  description: "$rcd_desc"
  homepage: "$rcd_homepage"
  license: "$rcd_license"
  author: "$rcd_author"
  repository: "$rcd_repository"
  repository_tag: "$CERC_REPO_TAG"
  app_version: "$rcd_app_version"
  app_type: "$CERC_APP_TYPE"
EOF


cat $RECORD_FILE
laconic -c $CONFIG_FILE cns record publish --filename $RECORD_FILE --user-key "${CERC_LACONIC_USER_KEY}" --bond-id ${CERC_LACONIC_BOND_ID}

rm -f $RECORD_FILE $CONFIG_FILE
