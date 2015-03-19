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

Symlink all dirs and files to your `~/` directory:

```
ln -s [full-path-to-your-home-dir]/.dotfiles/.bash_profile ~/.bash_profile

ln -s [full-path-to-your-home-dir]/.dotfiles/.bash_profile ~/.bashrc

ln -s [full-path-to-your-home-dir]/.dotfiles/.gitconfig ~/.gitconfig

ln -s [full-path-to-your-home-dir]/.dotfiles/.tmux.conf ~/.tmux.conf

ln -s [full-path-to-your-home-dir]/.dotfiles/.config [full-path-to-your-home-dir]/.config
```

When symlinking dirs, use absolute paths - don't use relative paths.
