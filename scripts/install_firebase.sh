INSTALL_DIR=/usr/local/bin
DOWNLOAD_URL="https://firebase.tools/bin/linux/latest"

sudo mkdir -p $INSTALL_DIR
sudo curl -o "$INSTALL_DIR/firebase" -L --progress-bar $DOWNLOAD_URL
sudo chmod +rx "$INSTALL_DIR/firebase"