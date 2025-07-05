#!/usr/bin/env bash

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │                                 Functions                                   │
# └─────────────────────────────────────────────────────────────────────────────┘

print() {
    local MESSAGE="${1}"  
    echo -e "\n\e[1;33m[INFO]\e[0m ${MESSAGE}..."
}

link_symlinks() {
    ln -sf ~/.dotfiles/config/bash/bash_profile ~/.bash_profile
    ln -sf ~/.dotfiles/config/bash/bash_profile ~/.bashrc
    ln -sf ~/.dotfiles/config/bash ~/.config/bash
    ln -sf ~/.dotfiles/config/tmux ~/.config/tmux
    ln -sf ~/.dotfiles/config/kitty ~/.config/kitty
    ln -sf ~/.dotfiles/config/gitconfig ~/.gitconfig
}

setup_tmux_plugins() {
    if [ ! -f ~/.config/tmux/plugins/tpm/README.md ]; then
        git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
        ln -sf ~/.dotfiles/config/tmux-powerline ~/.config/tmux-powerline
    fi
}

setup_base_16() {
    rm -rf ~/.config/base16-shell
    git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell
}

install_brew_list() {
    brew install awscli
    brew install bash
    brew install bash-completion
    brew install coreutils
    brew install diff-so-fancy
    brew install git
    brew install jq
    brew install nvm
    bfew install pyenv
    bfew install pipx
    brew install tmux
    brew install vim
    brew install tldr
    brew install gh
}

install_brew_casks() {
    brew install --cask alfred
    brew install --cask spotify
    brew install --cask whatsapp
    brew install --cask docker
    brew install --cask postman
    brew install --cask slack
    brew install --cask kitty
    brew install --cask todoist
    brew install --cask adobe-creative-cloud
    brew install --cask google-chrome
    brew install --cask rectangle
}

install_brew_fonts() {
    brew install font-source-code-pro
    brew install font-fantasque-sans-mono
    brew install font-inconsolata
    brew install font-hack
    brew install font-fira-code
    brew install font-jetbrains-mono
    brew install font-ubuntu-mono
    brew install font-space-mono
    brew install font-hack-nerd-font
    brew install font-fira-code-nerd-font
    brew install font-jetbrains-mono-nerd-font
    brew install font-ubuntu-mono-nerd-font
    brew install font-space-mono-nerd-font
}

post_brew_install_setup() {
  # install and setup node 
  nvm install --lts
  nvm latest default node
  
  # install and setup python 
  LATEST_PYTHON=$(pyenv install --list | grep -E '^\s*3\.[0-9]+\.[0-9]+$' | tr -d ' ' | tail -1)
  pyenv install "${LATEST_PYTHON}"
  pyenv global "${LATEST_PYTHON}"
}

install_lunar_vim_deps() {
  # lunarvim needs cargo (rust) 
  brew install rust
  brew install ripgrep
  brew install lazygit
  
  # lunarvim pynvim, and we can install i
  # globally with regular pip because we 
  # never use pynvim outside lvim anyway
  pip3 install pynvim --break-system-packages --user
}

install_lunar_vim() {
  if ! command -v jq &> /dev/null; then
    print "jq is required but not installed. Aborting."
    exit 1
  fi

  LV_BRANCH=$(curl -s https://api.github.com/repos/LunarVim/LunarVim/branches | \
    jq -r '.[].name' | \
    grep -E '^release-[0-9]+\.[0-9]+/neovim-[0-9]+\.[0-9]+$' | \
    sort -V | tail -n 1)

  if [ -z "${LV_BRANCH}" ]; then
    print "Failed to detect latest LunarVim release branch. Aborting."
    exit 1
  fi

  print "Detected latest LunarVim branch: ${LV_BRANCH}"

  tmpfile=$(mktemp)
  curl -s "https://raw.githubusercontent.com/LunarVim/LunarVim/${LV_BRANCH}/utils/installer/install.sh" -o "$tmpfile"
  bash "$tmpfile" <<EOF
n
n
n
EOF

  rm -f "$tmpfile"
}


# ┌─────────────────────────────────────────────────────────────────────────────┐
# │                                  Install                                    │
# └─────────────────────────────────────────────────────────────────────────────┘

print "Setting up symlinks"
link_symlinks

print "Setting up tmux"
setup_tmux

print "Setting up base16"
setup_base_16

print "Installing brew list"
brew update
install_brew_list

print "Installing brew casks"
install_brew_casks

print "Installing brew fonts"
install_brew_fonts

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │                                  Finished                                   │
# └─────────────────────────────────────────────────────────────────────────────┘

echo -e "\n\e[1;32m[SUCCES]\e[0m DONE.\n"

