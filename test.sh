if [[ $GITHUB_EVENT_NAME != 'pull_request' &&
($GITHUB_REF == 'refs/heads/release'||
$GITHUB_REF == '\\refs\\heads\\release') ]]; then
  SHOULD_RELEASE=true;
else
  SHOULD_RELEASE=false;
fi
echo "SHOULD_RELEASE: $SHOULD_RELEASE"