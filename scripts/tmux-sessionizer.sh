#!/usr/bin/env bash

cmd=$(find ~/Personal ~/ -mindepth 1 -maxdepth 1 -type d | fzf )

if [[ -z $cmd ]];then
    exit 1
fi
name=$(basename "$cmd" | tr ".|$" "_")
if [[ -z $TMUX ]]; then
    tmux new-session -s $name -c $cmd
else
    if ! tmux has-session -t $name 2>/dev/null; then
        tmux new-session -d -s $name -c $cmd
    fi

fi
#switch to the session
tmux switch-client -t $name
