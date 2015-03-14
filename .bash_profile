### SHELL SETTINGS ###

#Set CLICOLOR if you want Ansi Colors in iTerm2 
export CLICOLOR=1

#Set colors to match iTerm2 Terminal Colors
export TERM=xterm-256color

# #Base16 Shell (so iTerm can work with Base16)
BASE16_SHELL="$HOME/.config/base16-shell/base16-eighties.dark.sh"
[[ -s $BASE16_SHELL ]] && source $BASE16_SHELL ]]

#Vim-style history scrolling (j & k) 
set -o vi

#==========================
#==========================

### ALIASES ###

#Vim alias
alias v="vim"

#Alis 'rm' so as to always ask permission to delete
alias rm="rm -i"

#Show hidden files
alias la="ls -a"

#Long listing format
alias ll="ls -l"

#Long listing format, including hidden files
alias lal="ls -a -l"

#Go to previous dir
alias .,="cd -"

#Go to parent dir
alias ..="cd .."

#Go to Desktop
alias cdd="cd ~/Desktop/"

#Change Directory to Development directory
alias cdev="cd ~/Development/"

#Change Directory to Hackerati directory
alias cddh="cd ~/Development/Hackerati/"

#Edit .bash_profile
alias vimb="vim ~/.bash_profile"

#Edit .vimrc
alias vimrc="vim ~/.vimrc"

#Edit .tmux.conf
alias vimt="vim ~/.tmux.conf"

#Edit .gitconfig
alias vimg="vim ~/.gitconfig"

#==========================
#==========================

### GIT SETTINGS & ALIASES ###

#Git coloring
export LESS=-R

#Git bash completion (hombrew, mac only)
if [ -f `brew --prefix`/etc/bash_completion ]; then
	. `brew --prefix`/etc/bash_completion
fi

#Git status alias
alias gs="git status"

#Git add
alias ga="git add"

#Git reset
alias gr="git reset"

#Git pull
alias gp="git pull"

#Git add all
alias gall="git add --all"

#Git add untracked
alias gau="git add -u"
 
#Git checkout
alias gc="git checkout"

#Git checkout new branch
alias gcb="git checkout -b"

#Git ammend last commit
alias gam="git commit --amend"

#Git alias for git diff
alias gd="git diff"

#Git pretty log (custom git alias)
alias plog="git plog"

#Git Update all git submodules
alias gsmu="git submodule foreach git pull origin master"

# - Checkout master, pull from origin, checkout to previous branch, rebase off of master
# - Used to quickly bring current branch up-to-date with origin/master
function rebmast(){
	branch=$(git symbolic-ref --short -q HEAD)
	git checkout master
	git pull
	git checkout $branch
	git rebase master
}

#Git commit without having to enter quotes for message
function gcom(){
	message="${@} ";
	git commit -m "${message}"
}

#Git commit, then push to origin current branch
function gup(){
	gcom $@
	gpush
}

# - Git push current branch to corresponding origin branch
# - Pass 'f' as first argument in order to forcepush
function gpush(){
	branch=$(git symbolic-ref --short -q HEAD)
	if [ -z "$1" ]
	then
		git push origin $branch
		return
	else
		if [ $1 = "f" ]
		then
			git push origin "+${branch}"
		else
			echo "Do 'gpush f' to force push"
		fi
	fi
}

# - Rebase off of master, then push to current branch
# - Always force pushes
function rebmpush(){
	rebmast
	gpush f
}

#Commit, rebase off of master and force push to current branch
function grup(){
	gcom $@
	rebmast
	gpush f
}

#Add all changes, commit using custom function, rebase off of master and force push to current branch
function gtrans(){
	gall	
	gcom $@
	rebmast
	gpush f
}
