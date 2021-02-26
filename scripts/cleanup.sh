#!/usr/bin/bash
set -e

if ls shippable/codecoverage/PhantomJS* &>/dev/null; then
  mv -f shippable/codecoverage/PhantomJS*/* shippable/codecoverage
  rm -rf shippable/codecoverage/PhantomJS*
fi
if [[ -e shippable/notification.json ]]; then
  echo "Sending notice to Slack"
  curl -f -s -S -X POST $SLACK_URL -H "Content-Type: application/json" --data @shippable/notification.json
  echo
  echo "Sending notice to Gitter"
  curl -f -s -S -X POST $GITTER_URL -H "Content-Type: application/json" --data @shippable/notification.json
  echo
fi
