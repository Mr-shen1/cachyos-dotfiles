#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
if [[ -r "$HOME/.local/share/blesh/ble.sh" ]]; then
    . "$HOME/.local/share/blesh/ble.sh"
fi
eval "$(starship init bash)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

if [[ -r "$HOME/.local/bin/env" ]]; then
    . "$HOME/.local/bin/env"
fi
alias ll='ls -lhA'
alias la='ls -A'
alias l='ls -CF'
