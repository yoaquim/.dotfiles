#!/usr/bin/env bash

print() {
    local MESSAGE="${1}"  
    echo -e "\n\e[1;33m---------------------[INFO]\e[0m ${MESSAGE}..."
}

link_symlinks() {
    ln -sf ~/.dotfiles/config/bashrc/bashrc ~/.bash_profile
    ln -sf ~/.dotfiles/config/bashrc/bashrc ~/.bashrc
    ln -sf ~/.dotfiles/config/bashrc/bashrc_aliases ~/.config/bashrc/bashrc_aliases
    ln -sf ~/.dotfiles/config/bashrc/bashrc_functions ~/.config/bashrc/bashrc_functions
    ln -sf ~/.dotfiles/config/bashrc/bashrc_tools ~/.config/bashrc/bashrc_tools
    ln -sf ~/.dotfiles/config/bashrc/bashrc_git ~/.config/bashrc/bashrc_git
    ln -sf ~/.dotfiles/config/tmux/tmux.conf ~/.config/tmux/tmux.conf
    ln -sf ~/.dotfiles/config/kitty/kitty.conf ~/.config/kitty/kitty.conf
    ln -sf ~/.dotfiles/config/gitconfig ~/.gitconfig
}

setup_tmux() {
    if [ ! -f ~/.config/tmux/plugins/tpm/README.md ]; then
        git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
    fi
}

setup_base_16() {
    rm -rf ~/.config/base16-shell
    git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell
}

setup_brew_taps() {
    brew tap chrokh/tap
}

install_brew_list() {
    brew install awscli
    brew install bash
    brew install bash-completion
    brew install coreutils
    brew install diff-so-fancy
    brew install git
    brew install jq
    brew install node
    brew install nvm
    brew install the_silver_searcher
    brew install tmux
    brew install vim
    brew install tldr
    brew install gh
    brew install neovim
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


print "Setting up symlinks"
link_symlinks

print "Setting up tmux"
setup_tmux

print "Setting up base16"
setup_base_16

print "Tapping brew taps"
setup_brew_taps

print "Installing brew list"
install_brew_list

print "Installing brew casks"
install_brew_casks

print "Installing brew fonts"
install_brew_fonts

# ============================
# FINISHED
# ============================
echo -e "\n\e[1;32m[SUCCES]\e[0m DONE.\n"

