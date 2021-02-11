#!/usr/bin/bash

set -e
export PATH=$PATH:~/google-cloud-sdk/bin
export BUILD_GROUP_NUMBER=$(echo $BUILD_NUMBER | sed 's/\..*//')

rm -rf shippable
mkdir shippable

echo "Branch: $BRANCH; pull request: $PULL_REQUEST; build: $BUILD_GROUP_NUMBER"

echo "Building and running tests"
# Installing and running yarn directly uses an old version for some reason, and runs against an
# old version of Node, failing the engine prereq.  Using npx appears to be a workaround.
npx yarn install --pure-lockfile
npm run build
npm run lint
npm run test
echo $BRANCH $PULL_REQUEST
if [[ "$BRANCH" =~ "\\release" && "$PULL_REQUEST" = "false" ]]; then
  echo "{\"level\": \"error\", \"message\": \"Server [build $BUILD_GROUP_NUMBER]($BUILD_URL) deployment failed\", \"text\": \"Server <$BUILD_URL|build $BUILD_GROUP_NUMBER> deployment failed\"}" >shippable/notification.json

  echo "Creating Sentry release $BUILD_GROUP_NUMBER"
  curl -f -s -S -u $SENTRY_API_KEY: -X POST https://sentry.io/api/0/projects/$SENTRY_PROJECT/releases/ -H 'Content-Type: application/json' -d "{\"version\": \"$BUILD_GROUP_NUMBER\"}" || exit 1
  echo
  for filename in built/*; do
    if [ -f $filename ]; then
      echo "Uploading $filename to Sentry"
      curl -f -s -S -u $SENTRY_API_KEY: -X POST https://sentry.io/api/0/projects/$SENTRY_PROJECT/releases/$BUILD_GROUP_NUMBER/files/ -F file=@$filename -F name="/usr/src/app/$filename" || exit 1
      echo
    fi
  done
  for filename in built/libs/*; do
    if [ -f $filename ]; then
      echo "Uploading $filename to Sentry"
      curl -f -s -S -u $SENTRY_API_KEY: -X POST https://sentry.io/api/0/projects/$SENTRY_PROJECT/releases/$BUILD_GROUP_NUMBER/files/ -F file=@$filename -F name="/usr/src/app/$filename" || exit 1
      echo
    fi
  done

  echo "Tagging git commit"
  git tag -a "build-$BUILD_GROUP_NUMBER" -m "Build $BUILD_GROUP_NUMBER"
  git push --tags origin release

  echo "Deploying server..."
  echo "  REVIEWABLE_FIREBASE_AUTH: $REVIEWABLE_FIREBASE_AUTH" >>app.yaml
  echo "  REVIEWABLE_FIREBASE_PRIVATE_KEY: $REVIEWABLE_FIREBASE_PRIVATE_KEY" >>app.yaml
  echo "  REVIEWABLE_ENCRYPTION_PRIVATE_KEYS: $REVIEWABLE_ENCRYPTION_PRIVATE_KEYS" >>app.yaml
  echo "  REVIEWABLE_SMTP_URL: $REVIEWABLE_SMTP_URL" >>app.yaml
  echo "  REVIEWABLE_SERVER_SENTRY_DSN: $REVIEWABLE_SERVER_SENTRY_DSN" >>app.yaml
  echo "  REVIEWABLE_PING_URL: $REVIEWABLE_PING_URL" >>app.yaml
  echo "  REVIEWABLE_STRIPE_SECRET_KEY: $REVIEWABLE_STRIPE_SECRET_KEY" >>app.yaml
  echo "  REVIEWABLE_LOGGLY_TOKEN: $REVIEWABLE_LOGGLY_TOKEN" >>app.yaml
  echo "  REVIEWABLE_GITHUB_CLIENT_SECRET: $REVIEWABLE_GITHUB_CLIENT_SECRET" >>app.yaml
  echo "  REVIEWABLE_GITHUB_SECRET_TOKEN: $REVIEWABLE_GITHUB_SECRET_TOKEN" >>app.yaml
  echo "  AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY" >>app.yaml
  echo "  REVIEWABLE_VERSION: $BUILD_GROUP_NUMBER" >>app.yaml
  rm ~/.config/gcloud/logs/*/*.log
  gcloud app deploy app.yaml --version $BUILD_GROUP_NUMBER --stop-previous-version --quiet || { cat ~/.config/gcloud/logs/*/*.log; exit 1; }

  echo "App deployed, looking for obsolete versions to delete..."
  # Keep the previous version around for rollbacks
  limit=$(gcloud app versions list --filter='traffic_split=0' --format='value(id)' | wc -l)
  echo "Found $limit older versions"
  let "limit-=5" || true
  echo "Need to delete $limit of them"
  if [ $limit -gt 0 ]; then
    versions=$(gcloud app versions list --filter='traffic_split=0' --format='value(id)' --sort-by='last_deployed_time' --limit $limit)
    if [ ! -z "$versions" ]; then
      echo "Deleting obsolete versions: $versions"
      until gcloud app versions delete $versions --quiet
      do
        sleep 10  # Give the old version(s) a bit of time to drop their traffic, so we can delete them.
      done
    fi
  fi

  echo "{\"level\": \"info\", \"message\": \"Server [build $BUILD_GROUP_NUMBER]($BUILD_URL) deployed\", \"text\": \"Server <$BUILD_URL|build $BUILD_GROUP_NUMBER> deployed\"}" >shippable/notification.json
  echo "Server update done."

fi
