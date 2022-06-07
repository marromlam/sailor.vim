#!/usr/bin/env bash


# Kitty Tmux navigator
# SSH aware kitty change window
tmux if-shell '[ $SSH_TTY ]' 'to="--to=tcp:localhost:$KITTY_PORT "' 'to=""'
move='kitty @ ${to}kitten kittens/neighboring_window.py'


# (n)vim window checker
is_vim="ps -o state= -o comm= -t '#{pane_tty}' grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"


# these are the standard bindings if we just want to navigate between tmux and
# (n)vim.
# tmux bind-key -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
# tmux bind-key -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
# tmux bind-key -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
# tmux bind-key -n C-l if-shell "$is_vim" "send-keys C-l" "select-pane -R"


# these would be the bindings if we want to navigate beteen tmux and kitty
# tmux bind-key -n 'C-h' if-shell "[ #{pane_at_left} != 1 ]" "select-pane -L" "run-shell '$move left'"
# tmux bind-key -n 'C-j' if-shell "[ #{pane_at_bottom} != 1 ]" "select-pane -D" "run-shell '$move bottom'"
# tmux bind-key -n 'C-k' if-shell "[ #{pane_at_top} != 1 ]" "select-pane -U" "run-shell '$move top'"
# tmux bind-key -n 'C-l' if-shell "[ #{pane_at_right} != 1 ]" "select-pane -R" "run-shell '$move right'"


# this is the double if condition that checks if we are in a (n)vim window and
# if not then checks for tmux window and if not then navigates to kitty. So:
# if is_vim then:
#   send keys to (n)vim
# else:
#   if is_tmux then:
#     send keys to tmux
#   else:
#    send keys to kitty
#   endif
# endif
tmux bind-key -n 'C-h' if-shell "$is_vim" "send-keys C-h" "if-shell \"[ #{pane_at_left} != 1   ] \" \"select-pane -L\" \"run-shell '$move left'\""
tmux bind-key -n 'C-j' if-shell "$is_vim" "send-keys C-j" "if-shell \"[ #{pane_at_bottom} != 1 ] \" \"select-pane -D\" \"run-shell '$move bottom'\""
tmux bind-key -n 'C-k' if-shell "$is_vim" "send-keys C-k" "if-shell \"[ #{pane_at_top} != 1    ] \" \"select-pane -U\" \"run-shell '$move top'\""
tmux bind-key -n 'C-l' if-shell "$is_vim" "send-keys C-l" "if-shell \"[ #{pane_at_right} != 1  ] \" \"select-pane -R\" \"run-shell '$move right'\""


# vim: ft=tmux
