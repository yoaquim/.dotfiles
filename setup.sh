#!/bin/sh

function remove_symlinks {
    rm ~/.bash_profile

    rm ~/.bashrc

    rm ~/.bash_git

    rm ~/.gitconfig

    rm ~/.tmux.conf

    rm -rf ~/.config

    rm -rf ~/.scripts

    rm ~/.slate.js

    rm ~/.ideavimrc

    rm ~/.spacemacs
}

function link_symlinks {
    ln -s ~/.dotfiles/bash_profile ~/.bash_profile

    ln -s ~/.dotfiles/bash_profile ~/.bashrc

    ln -s ~/.dotfiles/bash_git ~/.bash_git

    ln -s ~/.dotfiles/gitconfig ~/.gitconfig

    ln -s ~/.dotfiles/tmux.conf ~/.tmux.conf

    ln -s ~/.dotfiles/config ~/.config

    ln -s ~/.dotfiles/scripts ~/.scripts

    ln -s ~/.dotfiles/slate.js ~/.slate.js

    ln -s ~/.dotfiles/ideavimrc ~/.ideavimrc

    ln -s ~/.dotfiles/spacemacs ~/.spacemacs
}

if [ -z  "$1" ]; then
    link_symlinks
else
    if [ $1="f" ]; then
        remove_symlinks
        link_symlinks
    fi
fi
