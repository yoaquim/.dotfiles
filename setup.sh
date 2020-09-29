#!/bin/sh

remove_symlinks() {
    rm ~/.bash_profile
    rm ~/.bashrc
    rm ~/.bash_git
    rm ~/.gitconfig
    rm ~/.tmux.conf
    rm -rf ~/.config
    rm ~/.slate.js
    rm ~/.ideavimrc
    rm ~/.spacemacs
    rm ~/.yabairc
    rm ~/.skhdrc
}

link_symlinks() {
    ln -s ~/.dotfiles/bash_profile ~/.bash_profile
    ln -s ~/.dotfiles/bash_profile ~/.bashrc
    ln -s ~/.dotfiles/bash_git ~/.bash_git
    ln -s ~/.dotfiles/bash_aliases ~/.bash_aliases
    ln -s ~/.dotfiles/gitconfig ~/.gitconfig
    ln -s ~/.dotfiles/tmux.conf ~/.tmux.conf
    ln -s ~/.dotfiles/config ~/.config
    ln -s ~/.dotfiles/slate.js ~/.slate.js
    ln -s ~/.dotfiles/ideavimrc ~/.ideavimrc
    ln -s ~/.dotfiles/spacemacs ~/.spacemacs
    ln -s ~/.dotfiles/yabairc ~/.yabairc
    ln -s ~/.dotfiles/yabairc ~/.skhdrc
}

if [ -z  "$1" ]; then
    link_symlinks
elif [ "${1}" = "f" ]; then
    remove_symlinks
    link_symlinks
else
    echo -e "\n\tOnly accepted flag if 'f'\n"
fi
