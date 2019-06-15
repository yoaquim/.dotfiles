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

# Custom bash prompt; shows git branch
PS1="[\[\033[32m\]\w]\[\033[0m\]\$(__git_ps1)\n\[\033[1;36m\]\u\[\033[32m\]$ \[\033[0m\]"

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

# Edit /etc/hosts
alias vetc="sudo vim /etc/hosts"

# Coreutils so "sb" alias can work
alias readlink=greadlink

# Source bash file
alias sb=". ~/.bash_profile"

# Flush IP cache
alias flush="sudo dscacheutil -flushcache;sudo killall -HUP mDNSResponder;say cache flushed"

# NPM alias so you can run npm scripts on silent mode
alias npms="npm -s"

# Delete all docker containers
dr="docker rm \$(docker ps -a -q)"
alias dkrm='eval ${dr}'

# Delete all docker images
dri="docker rmi \$(docker images -q)"
alias dkrmi='eval ${dri}'

# Bash into a docker image 
alias drun="docker run -it --entrypoint /bin/bash"

#==========================
# HELPER FUNCTIONS
#==========================

# --------------------------
# UP/FF
# --------------------------
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

# --------------------------
# TOGGLE_HIDDEN
# --------------------------
# Toggles if hidden (dotfiles) are shown on Finder

function toggle_hidden {
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

# --------------------------
# RENAME_EXTENSION
# --------------------------
# Rename extension for all files in a dir

function rename_extension {
    for f in *.${1}; do 
        mv -- "$f" "${f%.${1}}.${2}"
    done
}

# --------------------------
# MARK
# --------------------------
# Mark a dir so you can easily jump to it later

function mark {
    mkdir -p "$MARKPATH"; ln -s "$(pwd)" "$MARKPATH/$1"
}

# --------------------------
# UNMARK
# --------------------------
# Unmark  a marked dir
function unmark {
    rm -i "$MARKPATH/$1"
}

# --------------------------
# JUMP/J
# --------------------------
# Jump to bookmarked location
alias j="jump"
function jump {
    cd -P "$MARKPATH/$1" 2> /dev/null || echo "No such mark: $1"
}

# --------------------------
# MARKS
# --------------------------
# Print out current marked dirs

function marks {
    ls -l "$MARKPATH" | tail -n +2 | sed 's/  / /g' | cut -d' ' -f9- | awk -F ' -> ' '{printf "%-10s -> %s\n", $1, $2}'
}

# --------------------------
# TAB COMPLETION: MARKS
# --------------------------
# Tab completion for marks

function _completemarks {
    local cur=${COMP_WORDS[COMP_CWORD]}
    local marks=$(find $MARKPATH -type l | awk -F '/' '{print $NF}')
    COMPREPLY=($(compgen -W '${marks[@]}' -- "$cur"))
    return 0
}
complete -o default -o nospace -F _completemarks jump unmark

# --------------------------
# SAWSP
# --------------------------
# Switch between AWS_PROFILES

function sawsp {
    export AWS_DEFAULT_PROFILE="${1}"
}

# --------------------------
# WAWSP
# --------------------------
# Get current AWS_PROFILE

function wawsp {
    local account_num=$(aws sts get-caller-identity --output text --query 'Account')
    echo -e "\tProfile: ${AWS_DEFAULT_PROFILE}"
    echo -e "\tAccount: ${account_num}"
}

# --------------------------
# RENAME_EXTENSION_SUBDIRS
# --------------------------
# Rename file extensions in subdirs localted in current dir up to 4 levels deep

function rename_extension_subdirs {
    old_extension=${1}
    new_extension=${2}
    for d in $(find ./ -maxdepth 4 -type d)
    do
        (
            cd "${d}"
            for i in *"${old_extension}"
            do 
                extension="${i#*.}"
                if [ ".${extension}" == "${old_extension}" ]; then
                    mv -v "${i}" `basename "${i}" "${old_extension}"`"${new_extension}"
                fi
            done
        )
    done
}


# --------------------------
# RENAME_SUBDIRS
# --------------------------
# Rename subdirs in current dir

function rename_subdirs {
    old_name=${1}
    new_name=${2}
    for d in $(find ./ -maxdepth 4 -type d)
    do
        dir_to_rename="$(basename "${d}")"
        if [ "${dir_to_rename}" == "${old_name}" ]; then
            folder_name=$(dirname "${d}")
            final_name="${folder_name}/${new_name}"
            echo "${d} --> ${final_name}"
            mv "${d}" "${final_name}"
        fi
    done
}


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

#============================
# ADDED BY EXTERNAL TOOLS
#============================
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
eval "$(jenv init -)"
