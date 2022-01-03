#!/usr/bin/env bash

THIS_PATH=`pwd`

# kitty installation
# we just need to create some links to be able to navigate
KITTY_PATH="$HOME/.config/kitty"
ln -sf {$THIS_PATH,$KITTY_PATH}/neighboring_window.py
ln -sf {$THIS_PATH,$KITTY_PATH}/pass_keys.py

# ssh installation
# we only need this if we are installing in a ssh machine
# TODO: each shell needs its own config file.
#       we need to do some branchin here.
if [ $SSH_TTY ]; then
  echo "source $THIS_PATH/zsh_sail.sh" >> ~/.zshrc
fi

# tmux installation
# maybe we should create a warning to add the tmux plugin.
# it is a bit too hard to create the symbolic link. 
# TODO: create the warning.


# set -eou pipefail

# vim:foldmethod=marker
