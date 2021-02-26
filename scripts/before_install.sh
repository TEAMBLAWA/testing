set -e
export BUILD_GROUP_NUMBER=$(echo $BUILD_NUMBER | sed 's/\..*//')
echo "Build: $BUILD_GROUP_NUMBER"

sudo apt-get -qq update && sudo apt-get -qq -y install curl apt-transport-https

echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
sudo apt-get -qq update && sudo apt-get -qq -y install yarn

node --version
yarn --version
yarn global add grunt-cli bower firebase-tools@5.x
