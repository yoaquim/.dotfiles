#!/bin/sh
cat brewlist.txt | xargs -L 1 brew install

# intall base16-manager
echo -t "\n\nInstalling base16...\n\n"
brew tap chrokh/tap
brew install base16-manager
