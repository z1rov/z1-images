#!/usr/bin/env bash

alias forja='cd /opt/tools/forja'
alias mimikatz='cd /opt/tools/forja/mimikatz'

alias ll='ls -lahF --color=auto'
alias la='ls -la --color=auto'
alias grep='grep --color=auto'
alias cls='clear'

if [ -n "$BASH_VERSION" ]; then
    export PS1='\[\033[0;36m\][Z1:] \[\033[1;32m\]\w\[\033[0m\] # '
fi
cd "$HOME" 2>/dev/null
