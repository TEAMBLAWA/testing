#!/usr/bin/bash
if [[ $BRANCH =~ .*release$ ]]; then
        BUILD_TARGET='production'
        FIREBASE_PROJECT='firebase-reviewable'
elif [[ .*release-beta$ ]]; then
        BUILD_TARGET='beta'
        FIREBASE_PROJECT='reviewable-beta'
else
    echo "Unrecognized release branch: $BRANCH"
    exit 1
fi
echo $BUILD_TARGET
echo $FIREBASE_PROJECT