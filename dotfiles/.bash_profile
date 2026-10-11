#
# ~/.bash_profile
#

[[ -f "$HOME/.bashrc" ]] && . "$HOME/.bashrc"

if [[ -r "$HOME/.local/bin/env" ]]; then
    . "$HOME/.local/bin/env"
fi

toolbox_scripts="$HOME/.local/share/JetBrains/Toolbox/scripts"
if [[ -d "$toolbox_scripts" ]]; then
    PATH="$PATH:$toolbox_scripts"
fi
export PATH

