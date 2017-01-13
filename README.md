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

- Clone this repo into your `~/` directory:
 ```Shell
 cd ~/

 git clone https://github.com/yoaquim/.dotfiles.git
 ```

- Run `setup.sh` (will symlink into home dir):

 ```
 cd  ~/.dotfiles
 ./setup.sh
 ```

If you pass the `f` flag to setup (`./setup.sh -f`), it'll first delete all relevant symlinks before symlinking.

## Post-setup

### Homebrew

`brewlist.txt` is a list a of installed brew formulae. Running the `install_brew_list.sh` script will install said list. **Java should be installed _beforehand_, otherwise some installs (**`maven`**,** `sbt`**, etc) will fail**:

```
brew install java
```
### Bash

**Bash** is among the formulae in `brewlist`, and so installs an updated version of bash and must be linked. Running `link_bash.sh` will partly accomplish this, but the command spits out a URL that must be followed in order to finish linking.
