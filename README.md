# Dotfiles

## Intro

Contains all my personal dotfiles and dirs:

 - Bash Profile
 - Git Configuration
 - Slate Configuration
 - Config Directory (where some applications set configuration)
 - Tmux Configuration
 - IntelliJ vimrc settings and CLI launcher
 - i3wm & i3blocks for linux
 - [`yabai`](https://github.com/koekeishiya/yabai) & [`skhd`](https://github.com/koekeishiya/skhd/) config files

## Setup

- Clone this repo into your `~/` directory:
 ```Shell
 cd ~/

 git clone https://github.com/cintron/.dotfiles.git
 ```

- Run `setup.sh` to setup dotfiles. Need to specify for mac(m) or linux(l):

 ```
 cd  ~/.dotfiles
 ./setup.sh -l
 ```

## Mac Post-setup

### Homebrew
`brewlist.txt` contains the desired packages for a base setup. Running the `install_brew_list.sh` script will install the packages in that list.


### Bash
**Bash** is among the formulas in `brewlist`, and so installs an updated version of bash.

Mac OSX now ships with zsh as the default shell. In order to change it, add the correct homebrew bash path to `/etc/shells` and then run `chsh` accordingly:

```shell
# If Intel-based Mac
sudo sh -c 'echo /usr/local/bin/bash >> /etc/shells'
chsh -s /usr/local/bin/bash
echo 'eval "$(/usr/local/bin/brew shellenv)"' ~/.bash_local

# If M1 chip Mac
sudo sh -c 'echo /opt/homebrew/bin/bash >> /etc/shells'
chsh -s /opt/homebrew/bin/bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' ~/.bash_local
```

[This thread](https://apple.stackexchange.com/questions/291287/globstar-invalid-shell-option-name-on-macos-even-with-bash-4-x) has some more context if things don't work.


## Linux Post-setup

This guide helps with Lenovo fingerprint integration: https://forum.kde.org/viewtopic.php?f=309&t=175570
