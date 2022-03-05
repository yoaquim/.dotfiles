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

 git clone https://github.com/yoaquim/.dotfiles.git
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
**Bash** is among the formulas in `brewlist`, and so installs an updated version of bash; this sometimes leads to extra configuration that needs to happen.

[This thread](https://apple.stackexchange.com/questions/291287/globstar-invalid-shell-option-name-on-macos-even-with-bash-4-x) provides some insight, but here are some other actions that may help remedy this:

```
ln -s "$(which greadlink)" "$(dirname "$(which greadlink)")/readlink"
``` 

or

```
brew install coreutils
brew link coreutils
```

