#Dotfiles

##Intro

Contains all my personal dotfiles and dirs:

 - Bash Profile
 - Git Configuration
 - Slate Configuration
 - Config Directory (where some applications set configuration)
 - Tmux Configuration
 - IntelliJ vimrc settings and CLI launcher

##Setup

Just clone this repo into your `~/` directory:
```Shell
cd ~/

git clone https://github.com/yoaquim/.dotfiles.git
```
Then run `setup.sh` (will symlink into home dir):

```
cd  ~/.dotfiles
./setup.sh
```

If you pass the `f` flag to setup (`./setup.sh -f`), it'll first delete all relevant symlinks before symlinking.
