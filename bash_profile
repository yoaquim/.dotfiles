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
BASE16_SHELL="$HOME/.config/base16-shell/scripts/base16-materia.sh"
[[ -s $BASE16_SHELL ]] && source $BASE16_SHELL ]]

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

# Source bash file
alias sb=". ~/.bash_profile"

# Flush IP cache
alias flush="sudo dscacheutil -flushcache;sudo killall -HUP mDNSResponder;say cache flushed"

# Alias to build scala project from scratch with passed parameter as project name
alias scb="sh ~/.scripts/scala_build.sh"

#==========================
# HELPER FUNCTIONS
#==========================

# Go to previous dir as many times as input parameter
# if no input parameter, then just go back
# also ad "up" as an alias
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
#--------------------------------
# This section taken from:
# http://jeroenjanssens.com/2013/08/16/quickly-navigate-your-filesystem-from-the-command-line.html
# https://news.ycombinator.com/item?id=6229001 (comment by beders) 

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
#--------------------------------
#--------------------------------

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
