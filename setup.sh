#!/bin/sh

remove_symlinks() {
    pushd ~
    rm ~/.bash_profile
    rm ~/.bashrc
    rm ~/.bash_git
    rm ~/.bash_aliases
    rm ~/.gitconfig
    rm ~/.tmux.conf
    rm ~/.slate.js
    rm ~/.ideavimrc
    rm ~/.spacemacs
    rm ~/.yabairc
    popd
}

link_mac_symlinks() {
    ln -s ~/.dotfiles/bashrc/bashrc_mac ~/.bash_profile
    ln -s ~/.dotfiles/bashrc/bashrc_mac ~/.bashrc
    ln -s ~/.dotfiles/bashrc/bash_git_mac ~/.bash_git
    ln -s ~/.dotfiles/bashrc/bash_aliases ~/.bash_aliases
    ln -s ~/.dotfiles/gitconfig ~/.gitconfig
    ln -s ~/.dotfiles/tmux.conf ~/.tmux.conf
    ln -s ~/.dotfiles/slate.js ~/.slate.js
    ln -s ~/.dotfiles/ideavimrc ~/.ideavimrc
    ln -s ~/.dotfiles/spacemacs ~/.spacemacs
    ln -s ~/.dotfiles/yabairc ~/.yabairc
}

link_linux_symlinks() {
    ln -s ~/.dotfiles/bash/bashrc_linux ~/.bash_profile
    ln -s ~/.dotfiles/bash/bashrc_linux ~/.bashrc
    ln -s ~/.dotfiles/bash/bash_git_linux ~/.bash_git
    ln -s ~/.dotfiles/bash/bash_aliases ~/.bash_aliases
    ln -s ~/.dotfiles/gitconfig.linux ~/.gitconfig
    ln -s ~/.dotfiles/tmux.conf.linux ~/.tmux.conf
    ln -s ~/.dotfiles/slate.js ~/.slate.js
    ln -s ~/.dotfiles/ideavimrc ~/.ideavimrc
    ln -s ~/.dotfiles/spacemacs ~/.spacemacs
    ln -s ~/.dotfiles/yabairc ~/.yabairc
}

if [ "${2}" = "-f" ]; then
    remove_symlinks
elif [ ! -z "${2}" ] && [ "${2}" != "-f" ]; then
    echo "\n\tOnly accepted flag for second param is 'f'\n"
    exit 1
fi

if [ -z "${1}" ]; then
    echo "\n\tNeed to specify which OS, '-m' for Mac, '-l' for Linux\n"
elif [ "${1}" = "-m" ]; then
    link_mac_symlinks
elif [ "${1}" = "-l" ]; then
    link_linux_symlinks
else
    echo "\n\tValid flags for first param are 'l' or 'm'\n"
fi

