#!/usr/bin/env bash

THIS_PATH=`readlink -f $0`
THIS_PATH=`dirname $THIS_PATH`

if test -f "$THIS_PATH/installation_complete"; then
  # then the installation is complete
  exit
fi

# kitty installation
# we just need to create some links to be able to navigate
KITTY_PATH="$HOME/.config/kitty/kittens"
ln -sf {$THIS_PATH,$KITTY_PATH}/neighboring_window.py
ln -sf {$THIS_PATH,$KITTY_PATH}/pass_keys.py

# ssh installation
# we only need this if we are installing in a ssh machine
# TODO: each shell needs its own config file.
#       we need to do some branchin here.
if [ $SSH_TTY ]; then
  echo "source $THIS_PATH/sailor.zsh" >> ~/.zshrc
fi

# tmux installation
# maybe we should create a warning to add the tmux plugin.
# it is a bit too hard to create the symbolic link.
# TODO: create the warning.


# create an empty file to indicate that the installation is complete
touch $THIS_PATH/installation_complete

# vim: fdm=marker ft=sh
