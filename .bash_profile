### SHELL SETTINGS ###

#iTerm 2 ANSI colors
	# Set CLICOLOR if you want Ansi Colors in iTerm2 
export CLICOLOR=1
	# Set colors to match iTerm2 Terminal Colors
export TERM=xterm-256color

#Vim-style history scrolling (j & k) 
set -o vi


#==========================


### ALIASES ###

#Move to Development directory
alias cdd="cd ~/Development/"

#Move to Hackerati directory
alias cddh="cd ~/Development/Hackerati/"

#Edit .bash_profile
alias vimbp="vim ~/.bash_profile"

#Edit .vimrc
alias vimrc="vim ~/.vimrc"


#==========================


### GIT SETTINGS & ALIASES ###

#Git coloring
export LESS=-R

#Git bash completion
if [ -f `brew --prefix`/etc/bash_completion ]; then
	. `brew --prefix`/etc/bash_completion
fi

#Git status alias
alias gs="git status"

#Git add all
alias gall="git add --all"

#Git add untracked
alias gau="git add -u"
 
#Git checkout
alias gco="git checkout"

#Git checkout new branch
alias gcob="git checkout -b"

# - Checkout master, pull from origin, checkout to previous branch, rebase off of master
# - Used to quickly bring current branch up-to-date with origin/master
function rebmast(){
	branch=$(git symbolic-ref --short -q HEAD)
	git checkout master
	git pull
	git checkout $branch
	git rebase master
}

function gcomm(){
	message="${@} ";
	echo $message
	git commit -m "${message}"
}

function test(){
	echo "${@}";
}
