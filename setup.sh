#!/bin/sh

link_mac_symlinks() {
    ln -sf ~/.dotfiles/bashrc/bashrc_mac ~/.bash_profile
    ln -sf ~/.dotfiles/bashrc/bashrc_mac ~/.bashrc
    ln -sf ~/.dotfiles/bashrc/bash_git_mac ~/.bash_git
    ln -sf ~/.dotfiles/bashrc/bash_aliases ~/.bash_aliases
    ln -sf ~/.dotfiles/gitconfig ~/.gitconfig
    ln -sf ~/.dotfiles/tmux.conf ~/.tmux.conf
    ln -sf ~/.dotfiles/slate.js ~/.slate.js
    ln -sf ~/.dotfiles/ideavimrc ~/.ideavimrc
    ln -sf ~/.dotfiles/spacemacs ~/.spacemacs
    ln -sf ~/.dotfiles/yabairc ~/.yabairc
}

link_linux_symlinks() {
    ln -sf ~/.dotfiles/bashrc/bashrc_linux ~/.bash_profile
    ln -sf ~/.dotfiles/bashrc/bashrc_linux ~/.bashrc
    ln -sf ~/.dotfiles/bashrc/bash_git_linux ~/.bash_git
    ln -sf ~/.dotfiles/bashrc/bash_aliases ~/.bash_aliases
    ln -sf ~/.dotfiles/gitconfig.linux ~/.gitconfig
    ln -sf ~/.dotfiles/tmux.conf.linux ~/.tmux.conf
    ln -sf ~/.dotfiles/spacemacs ~/.spacemacs
}


# find config -maxdepth 1 -mindepth 1 -type d -exec ln -sf ../'{}' ~/.config/ \;
cp -a config/. ~/.config

if [ -z "${1}" ]; then
    echo "\n\tNeed to specify which OS, '-m' for Mac, '-l' for Linux\n"
elif [ "${1}" = "-m" ]; then
    link_mac_symlinks
elif [ "${1}" = "-l" ]; then
    link_linux_symlinks
else
    echo "\n\tValid flags for param are 'l' or 'm'\n"
fi

