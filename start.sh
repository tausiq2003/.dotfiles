#!/bin/bash




# this might be the nix os startup setup
# first add git, stow, vim to env packages and run it, nixos install.
# then git clone the dotfiles
# then run this start.sh, i can't remember everything
# then stow it
# before stowing delete your configuration files 
# then stow it
# after stowing i guess you are gtg, run nix flake lock, then see makefile use sudo nixos-rebuild switch --flake /etc/nixos#nixos, see if there is /etc/nixos or not and flake.lock is present or not.
# don't forget to git init the /etc/nixos.
# after stowing just see the makefile then everything should be gtg


# don't make files executable
find .dotfiles -type f -exec chmod 644 {} \;

# make directories executable
find .dotfiles -type d -exec chmod 755 {} \;


# git config --global user.email and user.name
# use signed commits and tags
# git config --global commit.gppsign true
# setup ssh
