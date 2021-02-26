#!/usr/bin/bash
set -e
echo "Branch: $BRANCH; pull request: $PULL_REQUEST; build: $BUILD_GROUP_NUMBER"

rm -rf shippable
mkdir shippable

NODE_ENV=production grunt dist || exit 1

if [[ "$BRANCH" == release* && "$PULL_REQUEST" = "false" ]]; then
  case $BRANCH in
    "release")
      BUILD_TARGET='production'
      FIREBASE_PROJECT='firebase-reviewable'
      ;;
    "release-beta")
      BUILD_TARGET='beta'
      FIREBASE_PROJECT='reviewable-beta'
      ;;
    *)
      echo "Unrecognized release branch: $BRANCH"
      exit 1
  esac

  echo "Deploying client to $BUILD_TARGET..."
  echo "{\"level\": \"error\", \"message\": \"Client [build $BUILD_GROUP_NUMBER]($BUILD_URL) deployment failed\", \"text\": \"Client <$BUILD_URL|build $BUILD_GROUP_NUMBER> deployment failed\"}" >shippable/notification.json

  echo "Creating Sentry release $BUILD_GROUP_NUMBER"
  curl -f -s -S -u $SENTRY_API_KEY: -X POST https://sentry.io/api/0/projects/$SENTRY_PROJECT/releases/ -H 'Content-Type: application/json' -d "{\"version\": \"$BUILD_GROUP_NUMBER\"}" || exit 1
  echo
  cd dist
  for filename in js/*; do
    echo "Uploading $filename to Sentry"
    curl -f -s -S -u $SENTRY_API_KEY: -X POST https://sentry.io/api/0/projects/$SENTRY_PROJECT/releases/$BUILD_GROUP_NUMBER/files/ -F file=@$filename -F name="$REVIEWABLE_HOST_URL/$filename" || exit 1
    echo
  done
  cd ..

  echo "Tagging git commit"
  git tag -a "build-$BUILD_GROUP_NUMBER" -m "Build $BUILD_GROUP_NUMBER"
  git push --tags origin $BRANCH

  echo "Deploying to Firebase hosting"
  firebase deploy --non-interactive --token "$FIREBASE_DEPLOY_TOKEN" --project "$FIREBASE_PROJECT" --public dist --only hosting,database --message "Build $BUILD_GROUP_NUMBER" || exit 1

  echo "{\"level\": \"info\", \"message\": \"Client [build $BUILD_GROUP_NUMBER]($BUILD_URL) deployed\", \"text\": \"Client <$BUILD_URL|build $BUILD_GROUP_NUMBER> deployed\"}" >shippable/notification.json
  echo "Client update done."
fi
