#!/usr/bin/env bash

languages=$(echo "c cpp python golang typescript javascript lua " | tr " " "\n")
core_utils=$(echo "find xargs sed awk grep fzf head tail uniq" | tr " " "\n")

selected=$(echo -e  "$languages\n$core_utils" | fzf)

read -p "your query: " query

if echo "$languages" | grep -qs $selected; then
    tmux split-window -p 20 -h bash -c  "curl cht.sh/$selected/$(echo "$query" | tr " " "+") | less"
else
    tmux split-window -p 20 -h bash -c  "curl cht.sh/$selected~$query | less"
    
fi
