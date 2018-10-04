#==================
# EXPORTS
#==================

# Dir for marking functions
export MARKPATH=$HOME/.marks

# Set CLICOLOR if you want Ansi Colors in iTerm2
export CLICOLOR=1

# Set colors to match iTerm2 Terminal Colors
export TERM=xterm-256color

#=====================
# SHELL SETTINGS
#=====================

# Base16 Shell (so iTerm can work with Base16)
BASE16_SHELL="$HOME/.config/base16-shell/"
[ -n "$PS1" ] && \
    [ -s "$BASE16_SHELL/profile_helper.sh" ] && \
        eval "$("$BASE16_SHELL/profile_helper.sh")"

# Vim-style history scrolling (j & k)
set -o vi

# Navigate to dirs by typing their name (no cd)
shopt -s autocd

#==================
# ALIASES
#==================

# Alias for clear
alias c="clear"
alias cl="clear"

# Vim alias
alias v="vim"

# Alias 'rm' so as to always ask permission to delete
alias rm="rm -i"

# Alias remove dir ('rmdir') to 'rmd'
alias rmd="rm -rf"

# Show hidden files, long listing format
alias la="ls -la"

# Long listing format
alias l="ls -l"
alias ll="ls -l"

# Human readable, long listing format
alias lh="ls -lh"

# Human readable, show hidden files, long listing format
alias lah="ls -lah"
alias lha="ls -lah"

# Go to previous dir
alias ...="cd -"

# Go to parent dir
alias ..="cd .."

# Go to vim directory
alias cdv="cd ~/.vim"

# Go to dotfiles directory
alias cd.="cd ~/.dotfiles"

# Go to Desktop
alias cdd="cd ~/Desktop/"

# Change Directory to Dropbox directory
alias cdb="cd ~/Dropbox/"

# Change Directory to Projects directory
alias cdp="cd ~/Projects/"

# `touch` alias (create new file)
alias t="touch"

# Edit .bash_profile
alias vb="vim ~/.bash_profile"

# Edit .bash_git
alias vbg="vim ~/.bash_git"

# Edit .bash_local
alias vbl="vim ~/.bash_local"

# Edit .vimrc
alias vrc="vim ~/.vimrc"

# Edit .tmux.conf
alias vt="vim ~/.tmux.conf"

# Edit .gitconfig
alias vg="vim ~/.gitconfig"

# Coreutils so "sb" alias can work
alias readlink=greadlink

# Source bash file
alias sb=". ~/.bash_profile"

# Flush IP cache
alias flush="sudo dscacheutil -flushcache;sudo killall -HUP mDNSResponder;say cache flushed"

# Alias to build scala project from scratch with passed parameter as project name
alias scb="sh ~/.scripts/scala_build.sh"

# NPM alias so you can run npm scripts on silent mode
alias npms="npm -s"

# Docker remove all container
x="docker rm \$(docker ps -a -q)"
alias drm="echo ${x}"

# Docker remove all container
#alias drmi="docker rmi -f `$(docker images -q)`"

#==========================
# HELPER FUNCTIONS
#==========================

# Go to previous dir as many times as input parameter
# if no input parameter, then just go back
# also add "ff" as an alias to function
alias ff="up"
function up(){
    counter=$1;
    if [ -z "$1" ]; then
        ..
        return
    fi
    while [ $counter -gt 0 ]
    do
        ..
        counter=$[$counter-1]
    done

}

# Toggles if hidden (dotfiles) are shown on Finder
function toggle-hidden {
    TOGGLE=$HOME/.hidden-files-shown
    if [ ! -e $TOGGLE ]; then
        touch $TOGGLE
        defaults write com.apple.finder AppleShowAllFiles YES
    else
        rm -f $TOGGLE
        defaults write com.apple.finder AppleShowAllFiles NO
    fi

    killall Finder
}

#--------------------------------
# This section taken from:
# http://jeroenjanssens.com/2013/08/16/quickly-navigate-your-filesystem-from-the-command-line.html
# https://news.ycombinator.com/item?id=6229001 (comment by beders)

function durge {
# options:
# remove stopped containers and untagged images
#   $ dkcleanup 
# remove all stopped|running containers and untagged images
#   $ dkcleanup --reset
# remove containers|images|tags matching {repository|image|repository\image|tag|image:tag}
# pattern and untagged images
#   $ dkcleanup --purge {image}
# everything
#   $ dkcleanup --nuclear

if [ "$1" == "--reset" ]; then
    # Remove all containers regardless of state
    docker rm -vf $(docker ps -a -q) 2>/dev/null || echo "No more containers to remove."
elif [ "$1" == "--purge" ]; then
    # Attempt to remove running containers that are using the images we're trying to purge first.
    (docker rm -vf $(docker ps -a | grep "$2/\|/$2 \| $2 \|:$2\|$2-\|$2:\|$2_" | awk '{print $1}') 2>/dev/null || echo "No containers using the \"$2\" image, continuing purge.") &&\
    # Remove all images matching arg given after "--purge"
    docker rmi $(docker images | grep "$2/\|/$2 \| $2 \|$2 \|$2-\|$2_" | awk '{print $3}') 2>/dev/null || echo "No images matching \"$2\" to purge."
else
    # This alternate only removes "stopped" containers
    docker rm -vf $(docker ps -a | grep "Exited" | awk '{print $1}') 2>/dev/null || echo "No stopped containers to remove."
fi

if [ "$1" == "--nuke" ]; then
    docker rm -vf $(docker ps -a -q) 2>/dev/null || echo "No more containers to remove."
    docker rmi $(docker images -q) 2>/dev/null || echo "No more images to remove."
else
    # Always remove untagged images
    docker rmi $(docker images | grep "<none>" | awk '{print $3}') 2>/dev/null || echo "No untagged images to delete."
fi
}

# Mark a dir so you can easily jump to it later
function mark {
    mkdir -p "$MARKPATH"; ln -s "$(pwd)" "$MARKPATH/$1"
}

# Unmark  a marked dir
function unmark {
    rm -i "$MARKPATH/$1"
}

# Jump to bookmarked location
function jump {
    cd -P "$MARKPATH/$1" 2> /dev/null || echo "No such mark: $1"
}

# Print out current marked dirs
function marks {
    ls -l "$MARKPATH" | tail -n +2 | sed 's/  / /g' | cut -d' ' -f9- | awk -F ' -> ' '{printf "%-10s -> %s\n", $1, $2}'
}

# Tab completion for marks
function _completemarks {
    local cur=${COMP_WORDS[COMP_CWORD]}
    local marks=$(find $MARKPATH -type l | awk -F '/' '{print $NF}')
    COMPREPLY=($(compgen -W '${marks[@]}' -- "$cur"))
    return 0
}
complete -o default -o nospace -F _completemarks jump unmark

#==================
# BASH FILES
#==================

# Source local bash file
if [ -f ~/.bash_local ]; then
    source ~/.bash_local
fi

# Source git bash shortcuts
if [ -f ~/.bash_git ]; then
    source ~/.bash_git
fi

#============================
# ITERM2 SHELL INTEGRATION
#============================
test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

# added by travis gem
[ -f /Users/Asgard/.travis/travis.sh ] && source /Users/Asgard/.travis/travis.sh

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

# added by travis gem
[ -f /Users/yoaquim/.travis/travis.sh ] && source /Users/yoaquim/.travis/travis.sh
