#!/usr/bin/bash

set -e

if [[ "$BRANCH" = "release" && "$PULL_REQUEST" = "false" ]]; then

  # Get the actual private key (passed through an env var) into the key file that gcloud demands.
  # We need to escape the \n escape sequences, so they'll make it into the JSON file unscathed.
  sed -i "s|SERVICE_ACCOUNT_PRIVATE_KEY|$(echo $SERVICE_ACCOUNT_PRIVATE_KEY | sed -e 's/\\/\\\\/g')|" service_account_key.json

  sudo apt-get -qq update && sudo apt-get -qq -y install curl apt-transport-https

  export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
  echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

  sudo apt-get -qq update && sudo apt-get -qq -y install google-cloud-sdk

  gcloud auth activate-service-account --key-file=service_account_key.json --project=reviewable-prod
  gcloud info

fi
