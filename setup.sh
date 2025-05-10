#!/usr/bin/env bash

# ============================
# HELPERS
# ============================
print() {
    local MESSAGE="${1}"  
    echo -e "\n\e[1;33m---------------------[INFO]\e[0m ${MESSAGE}..."
}

link_mac_symlinks() {
    ln -sf ~/.dotfiles/bashrc/bashrc_mac ~/.bash_profile
    ln -sf ~/.dotfiles/bashrc/bashrc_mac ~/.bashrc
    ln -sf ~/.dotfiles/bashrc/bashrc_git_mac ~/.bashrc_git
    ln -sf ~/.dotfiles/bashrc/bashrc_aliases ~/.bashrc_aliases
    ln -sf ~/.dotfiles/bashrc/bashrc_functions ~/.bashrc_functions
    ln -sf ~/.dotfiles/bashrc/bashrc_tools ~/.bashrc_tools
    ln -sf ~/.dotfiles/gitconfig ~/.gitconfig
    ln -sf ~/.dotfiles/tmux.conf ~/.tmux.conf
    ln -sf ~/.dotfiles/ideavimrc ~/.ideavimrc
}

link_linux_symlinks() {
    ln -sf ~/.dotfiles/bashrc/bashrc_linux ~/.bash_profile
    ln -sf ~/.dotfiles/bashrc/bashrc_linux ~/.bashrc
    ln -sf ~/.dotfiles/bashrc/bashrc_git_linux ~/.bashrc_git
    ln -sf ~/.dotfiles/bashrc/bashrc_aliases ~/.bashrc_aliases
    ln -sf ~/.dotfiles/bashrc/bashrc_functions ~/.bashrc_functions
    ln -sf ~/.dotfiles/bashrc/bashrc_tools ~/.bashrc_tools
    ln -sf ~/.dotfiles/gitconfig.linux ~/.gitconfig
    ln -sf ~/.dotfiles/tmux.conf.linux ~/.tmux.conf
}

setup_i3blocks() {
    sudo apt install fonts-font-awesome -y
    git clone https://github.com/Anachron/i3blocks.git tmp
    sudo cp -R tmp/blocks/. /usr/share/i3blocks
    rm -rf tmp
}

setup_tmux() {
    if [ ! -f ~/.tmux/plugins/tpm/README.md ]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    fi
}

setup_rectangle() {
    brew install --cask rectangle
}

setup_base_16() {
    rm -rf ~/.config/base16-shell
    git clone https://github.com/yoaquim/base16-shell.git ~/.config/base16-shell
}

setup_brew_taps() {
    brew tap homebrew/cask-fonts
    brew tap chrokh/tap
}

setup_warp() {
    ln -sf ~/.dotfiles/warp ~/.warp
}

install_brew_list() {
    cat brewlist.txt | xargs -L 1 brew install
}

install_brew_casks() {
    cat brewlist.cask.txt | xargs -L 1 brew install --cask
}

install_brew_fonts() {
    brew install font-hack
    brew install font-source-code-pro
    brew install font-fira-code
    brew install font-jetbrains-mono
    brew install font-fantasque-sans-mono
    brew install font-ubuntu-mono
    brew install font-space-mono
    brew install font-inconsolata
}

install_gh_copilot() {
    gh auth login
    gh extension install github/gh-copilot
}

setup_cursor() {
    local os_flag="$1"
    local cursor_settings_path=""

    print "Setting up Cursor editor"

    if [ "$os_flag" = "-m" ]; then
        cursor_settings_path="$HOME/Library/Application Support/Cursor/User/settings.json"
    elif [ "$os_flag" = "-l" ]; then
        cursor_settings_path="$HOME/.config/Cursor/User/settings.json"
    else
        echo "Unsupported OS flag for Cursor setup: $os_flag"
        return 1
    fi

    # Ensure target directory exists
    mkdir -p "$(dirname "$cursor_settings_path")"

    # Symlink settings.json
    ln -sf ~/.dotfiles/cursor/settings.json "$cursor_settings_path"

    # Install extensions if Cursor CLI exists
    if command -v cursor >/dev/null 2>&1; then
        print "Installing Cursor extensions"
        xargs -a ~/.dotfiles/cursor/extensions.txt -L 1 cursor --install-extension
    else
        echo "Cursor CLI not found. Please ensure it's installed and in your PATH."
    fi
}

# ============================
# INSTALL FOR SPECIFIC OS
# ============================

if [ -z "${1}" ]; then
    echo -e "\nSpecify which OS: '-m' for Mac, '-l' for Linux\n"
    exit 1
elif [ "${1}" = "-m" ]; then
    print "Setting up symlinks"
    link_mac_symlinks

    print "Setting up tmux"
    setup_tmux

    print "Setting up Rectangle"
    setup_rectangle

    print "Setting up base16"
    setup_base_16

    print "Setting up warp"
    setup_warp

    print "Tapping brew taps"
    setup_brew_taps

    print "Installing brew fonts"
    install_brew_fonts

    print "Installing brew list"
    install_brew_list

    print "Installing brew casks"
    install_brew_casks

    print "Setting up Cursor"
    setup_cursor -m
elif [ "${1}" = "-l" ]; then
    print "Setting up symlinks"
    link_linux_symlinks

    print "Setting up i3blocks"
    setup_i3blocks

    print "Setting up tmux"
    setup_tmux

    print "Setting up Cursor"
    setup_cursor -l
else
    echo -e "\n\tValid flags for param are 'l' or 'm'\n"
    exit 1
fi

# ============================
# FINISHED
# ============================
echo -e "\n\e[1;32m[SUCCES]\e[0m DONE.\n"  # Bold green text

