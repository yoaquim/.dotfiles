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
BASE16_SHELL="$HOME/.config/base16-shell/base16-monokai.dark.sh"
[[ -s $BASE16_SHELL ]] && source $BASE16_SHELL ]]

# Vim-style history scrolling (j & k)
set -o vi


#==================
# ALIASES
#==================

# Alias for clear
alias c="clear"

# Vim alias
alias v="vim"

# Alias 'rm' so as to always ask permission to delete
alias rm="rm -i"

# Alias remove dir ('rm -rf') to 'rmd'
alias rmd="rm -rf"

# Show hidden files
alias la="ls -a"

# Long listing format
alias l="ls -l"
alias ll="ls -l"

# Long listing format, including hidden files
alias lal="ls -a -l"

# Go to previous dir
alias .,="cd -"

# Go to parent dir
alias ..="cd .."

# Go to vim directory
alias cdv="cd ~/.vim"

# Go to dotfiles directory
alias cd.="cd ~/.dotfiles"

# Go to Desktop
alias cdd="cd ~/Desktop/"

# Change Directory to Development directory
alias cdev="cd ~/Development/"

# Change Directory to Hackerati directory
alias cddh="cd ~/Development/Hackerati/"

# `touch` alias (create new file)
alias t="touch"

# Edit .bash_profile
alias vb="vim ~/.bash_profile"

# Edit .bash)local
alias vl="vim ~/.bash_local"

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

#==========================
# HELPER FUNCTIONS
#==========================

# Go to previous dir as many times as input parameter
# if no input parameter, then just go back
# also ad "up" as an alias
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
alias ff="up"

# Bookmark dirs, unmarks them, and jump to them
# http://jeroenjanssens.com/2013/08/16/quickly-navigate-your-filesystem-from-the-command-line.html
function jump {
    cd -P "$MARKPATH/$1" 2> /dev/null || echo "No such mark: $1"
}

function mark { 
    mkdir -p "$MARKPATH"; ln -s "$(pwd)" "$MARKPATH/$1"
}

function unmark {
    rm -i "$MARKPATH/$1"
}

function marks {
    ls -l "$MARKPATH" | tail -n +2 | sed 's/  / /g' | cut -d' ' -f9- | awk -F ' -> ' '{printf "%-10s -> %s\n", $1, $2}'
}

#----!!!!!!!!!!!!-----
# NOT WORKING 
#----!!!!!!!!!!!!-----

# Tab completion for marks
#--------------------
# _completemarks() {
#   local curw=${COMP_WORDS[COMP_CWORD]}
#   local wordlist=$(find $MARKPATH -type l -printf "%f\n")
#   COMPREPLY=($(compgen -W '${wordlist[@]}' -- "$curw"))
#   return 0
# }
#complete -F _completemarks jump unmark

#==========================
# GIT SETTINGS & ALIASES
#==========================

# Show current Git branch on bash prompt
PS1="[\[\033[32m\]\w]\[\033[0m\]\$(__git_ps1)\n\[\033[1;36m\]\u\[\033[32m\]$ \[\033[0m\]"

# Git coloring
export LESS=-R

# Git bash completion (hombrew, mac only)
if [ -f `brew --prefix`/etc/bash_completion ]; then
	. `brew --prefix`/etc/bash_completion
fi

# Git status alias
alias gs="git status"

# Git add
alias ga="git add"

# Git reset
alias gr="git reset"

# Git reset hard
alias grh="git reset --hard"

# Git pull
alias gp="git pull"

# Git push
alias gpush="git push"

# Git pull with rebase
alias gpr="git pull --rebase"

# Git fetch
alias gf="git fetch"

# Git log
alias gl="git log"

# Git add all
alias gall="git add --all"

# Git add untracked
alias gau="git add -u"

# Git checkout
alias gc="git checkout"

# Git checkout new branch
alias gcb="git checkout -b"

# Git branch alias
alias gb="git branch"

# Git ammend last commit
alias gam="git commit --amend"

# Git alias for git diff
alias gd="git diff"

# Git alias for git diff --staged
alias gds="git diff --staged"

# Git pretty log (custom git alias)
alias glog="git plog"

# Git update all git submodules
alias gsmu="git submodule foreach git pull origin master"

# Git initialize all plugins, recursively (sub-plugins); sometimes works better than 'gsmu' alias
alias gsmi="git submodule update --init --recursive"


# Git commit without having to enter quotes for message
function gcom(){
	message="${@} ";
	git commit -m "${message}"
}

# Git commit, then push to origin current branch
function gup(){
	gcom $@
	gpush
}

# Stash changes, checkout master, pull from origin, checkout to previous branch, rebase off of master, then pop stashed changes
# Used to quickly bring current branch up-to-date with origin/master
function rebmast(){
        git stash
	branch=$(git symbolic-ref --short -q HEAD)
	git checkout master
	git pull
	git checkout $branch
	git rebase master
        git stash pop
}


#==================
# BASH FILES
#==================

# Source local bash file
if [ -f ~/.bash_local ]; then
    source ~/.bash_local
fi
