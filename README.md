#Dotfiles

##Intro

Contains all my personal dotfiles and dirs:

 - Bash Profile
 - Git Configuration
 - Config Directory (where some applications set configuration)
 - Tmux Configuration

##Installation

Just clone this repo into your `~/` directory:
```Shell
cd ~/

git clone https://github.com/yoaquim/.dotfiles.git
```

After that, make sure you initialize any git submodules:
```Shell
cd ~/.dotfiles

git submodule update --init --recursive
```

If you ever need to update git submodules, just do:

```Shell
cd ~/.dotfiles

git submodule foreach git pull origin master
```

##Setup

Symlink all dirs and files to your `~/` directory, either manually, or by running `setup.sh`:

```
cd  ~/.dotfiles
./setup.sh
```

When symlinking dirs manually, use absolute paths - don't use relative paths.
