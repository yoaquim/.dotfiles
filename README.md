# Dotfiles

## Intro


#### **Requires [homebrew](https://brew.sh/) to be installed.**


Sets up my cli environment and installs my default apps:
 - Bash Profile + subfiles for organization
 - Tmux Configuration
 - Git Configuration
 - Neovim Configuration, using [mini.nvim](https://github.com/echasnovski/mini.nvim)
 - [Kitty](https://sw.kovidgoyal.net/kitty/) setup and config
 - [Rectangle](https://github.com/rxhanson/Rectangle) config
 - [Base16 Colors](https://github.com/chriskempson/base16-shell)
 - [Installs my defaults apps + tools via brew](https://github.com/yoaquim/.dotfiles/blob/master/install.sh#L29-L75)

## Setup

- Clone this repo into your `~/` directory:
 ```Shell
 cd ~/
 git clone https://github.com/cintron/.dotfiles.git
 ```

- Run `install.sh` to init

 ```
 cd  ~/.dotfiles
 ./install.sh
 ```


### Bash
**Bash** is among the brew formulas installed, which means it installs an updated version of bash.

Mac OSX now ships with zsh as the default shell. In order to change it, add the correct homebrew bash path to `/etc/shells` and then run `chsh` accordingly:

```shell
sudo sh -c 'echo /opt/homebrew/bin/bash >> /etc/shells'
chsh -s /opt/homebrew/bin/bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' ~/.config/bashrc/bashrc_local
```

[This thread](https://apple.stackexchange.com/questions/291287/globstar-invalid-shell-option-name-on-macos-even-with-bash-4-x) has some more context if things don't work.

