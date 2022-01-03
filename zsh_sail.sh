#!/usr/bin/env bash

# Set KITTY_PORT env variable
if [ $SSH_TTY ] && ! [ -n "$TMUX" ]; then
  export KITTY_PORT=`kitty @ ls 2>/dev/null | grep "[0-9]:/tmp/mykitty" | head -n 1 | cut -d : -f 1 | cut -d \" -f 2`
fi

_neighbor_kitty_h () { kitty @ kitten neighboring_window.py left }
_neighbor_kitty_j () { kitty @ kitten neighboring_window.py bottom }
_neighbor_kitty_k () { kitty @ kitten neighboring_window.py top }
_neighbor_kitty_l () { kitty @ kitten neighboring_window.py right }

# create zsh dont-remember-the-name-of-this-shit
zle -N _neighbor_kitty_h
zle -N _neighbor_kitty_j
zle -N _neighbor_kitty_k
zle -N _neighbor_kitty_l

# create bindings to those kitty commands
bindkey "^h" _neighbor_kitty_h
bindkey "^j" _neighbor_kitty_j
bindkey "^k" _neighbor_kitty_k
bindkey "^l" _neighbor_kitty_l

set -eou pipefail

# vim:foldmethod=marker
