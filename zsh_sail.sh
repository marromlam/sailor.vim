#!/usr/bin/env bash

# TODO: if we are on ssh and tmux this is not going to work
#       suggestions ...

# Set KITTY_PORT env variable
if [ $SSH_TTY ] && ! [ -n "$TMUX" ]; then
  export KITTY_PORT=`kitty @ ls 2>/dev/null | grep "[0-9]:/tmp/mykitty" | head -n 1 | cut -d : -f 1 | cut -d \" -f 2`
fi

_sail_kitty_h () { kitty @ kitten neighboring_window.py left }
_sail_kitty_j () { kitty @ kitten neighboring_window.py bottom }
_sail_kitty_k () { kitty @ kitten neighboring_window.py top }
_sail_kitty_l () { kitty @ kitten neighboring_window.py right }

# create zsh dont-remember-the-name-of-this-shit
zle -N _sail_kitty_h
zle -N _sail_kitty_j
zle -N _sail_kitty_k
zle -N _sail_kitty_l

# create bindings to those kitty commands
bindkey "^h" _sail_kitty_h
bindkey "^j" _sail_kitty_j
bindkey "^k" _sail_kitty_k
bindkey "^l" _sail_kitty_l

# vim:foldmethod=marker
