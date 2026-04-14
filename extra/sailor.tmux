#!/usr/bin/env bash

# Kitty and Wezterm Tmux navigator

# SSH aware kitty change window
# TODO: make this work with wezterm
tmux if-shell '[ $SSH_TTY ]' 'to="--to=tcp:localhost:$KITTY_PORT "' 'to=""'

# check if $WEZTERM_EXECUTABLE is set or not. If it is then we use the wezterm
# cli to navigate between panes. If not then we use kitty to navigate between
# panes.
if [ -z "$WEZTERM_EXECUTABLE" ]; then
  MOVE="kitty @ ${to}kitten kittens/neighboring_window.py"
else
  MOVE="${WEZTERM_MOVE}"
  WEZTERM_CLI="env -u WEZTERM_UNIX_SOCKET wezterm cli"
  WEZTERM_PANE_ID="${WEZTERM_CLI}"' list-clients | awk "{print $(NF)}" | tail -1'
  function get_id () {
    env -u WEZTERM_UNIX_SOCKET wezterm cli list-clients | awk '{print $(NF)}' | tail -1
  }
  # WEZTERM_MOVE="${WEZTERM_CLI} activate-pane-direction --pane-id ${WEZTERM_PANE_ID}"
  MOVE=${WEZTERM_CLI}" activate-pane-direction --pane-id $(get_id)"
fi


# (n)vim window checker
# is_vim="ps -o state= -o comm= -t '#{pane_tty}' grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
IS_VIM="ps -o state= -o comm= -t '#{pane_tty}' \
        | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?)(diff)?$'"
# is_vim="run-shell \"tmux lsw -F '#{window_name}#{window_active}'|sed -n 's|^\(.*\)1$|\1|p'\""
# IS_VIM='tmux lsw -F "#{window_name}#{window_active}"'
# IS_VIM='tmux run-shell "ps -o comm= -t '#{pane_tty}'" | tail -1'
# is_vim="#W"


# these are the standard bindings if we just want to navigate between tmux and
# (n)vim.
# tmux bind-key -n C-h if-shell "[[ '$is_vim' = *'vim'* ]]" "run-shell 'echo vim'" "run-shell 'echo tmux'" #"select-pane -L"
# tmux bind-key -n C-h if-shell "[[ '$is_vim' = *'vim'* ]]" "send-keys C-h" "select-pane -L"
# tmux bind-key -n C-j if-shell "[[ '$is_vim' = *'vim'* ]]" "send-keys C-j" "select-pane -D"
# tmux bind-key -n C-k if-shell "[[ '$is_vim' = *'vim'* ]]" "send-keys C-k" "select-pane -U"
# tmux bind-key -n C-l if-shell "[[ '$is_vim' = *'vim'* ]]" "send-keys C-l" "select-pane -R"


# these would be the bindings if we want to navigate beteen tmux and kitty
# tmux bind-key -n 'C-h' if-shell "[ #{pane_at_left} != 1 ]" "select-pane -L" "run-shell '$move left'"
# tmux bind-key -n 'C-j' if-shell "[ #{pane_at_bottom} != 1 ]" "select-pane -D" "run-shell '$move bottom'"
# tmux bind-key -n 'C-k' if-shell "[ #{pane_at_top} != 1 ]" "select-pane -U" "run-shell '$move top'"
# tmux bind-key -n 'C-l' if-shell "[ #{pane_at_right} != 1 ]" "select-pane -R" "run-shell '$move right'"

# OLD APPROACH
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
# tmux bind-key -n C-h if-shell "[[ '$IS_VIM' = *'vim'* ]]" "send-keys C-h" "if-shell \"[ #{pane_at_left} != 1   ] \" \"select-pane -L\" \"run-shell '($MOVE left)' \""
# tmux bind-key -n C-j if-shell "[[ '$IS_VIM' = *'vim'* ]]" "send-keys C-j" "if-shell \"[ #{pane_at_bottom} != 1 ] \" \"select-pane -D\" \"run-shell '($MOVE bottom) \""
# tmux bind-key -n C-k if-shell "[[ '$IS_VIM' = *'vim'* ]]" "send-keys C-k" "if-shell \"[ #{pane_at_top} != 1    ] \" \"select-pane -U\" \"run-shell '($MOVE top) \""
# tmux bind-key -n C-l if-shell "[[ '$IS_VIM' = *'vim'* ]]" "send-keys C-l" "if-shell \"[ #{pane_at_right} != 1  ] \" \"select-pane -R\" \"run-shell '($MOVE right) \""

# NEW APPROACH -- more robust
#                        if is_vim then:
#                                                       else:
#                                                                                                 is_tmux
#                                                                                                                                 wezterm/kitty
tmux bind-key -n C-h if-shell "$IS_VIM" "send-keys C-h" "if-shell \"[ #{pane_at_left} != 1   ]\" \"select-pane -L\" \"run-shell '($MOVE left)   || exit 0' \""
tmux bind-key -n C-j if-shell "$IS_VIM" "send-keys C-j" "if-shell \"[ #{pane_at_bottom} != 1 ]\" \"select-pane -D\" \"run-shell '($MOVE bottom) || exit 0' \""
tmux bind-key -n C-k if-shell "$IS_VIM" "send-keys C-k" "if-shell \"[ #{pane_at_top} != 1    ]\" \"select-pane -U\" \"run-shell '($MOVE top)    || exit 0' \""
tmux bind-key -n C-l if-shell "$IS_VIM" "send-keys C-l" "if-shell \"[ #{pane_at_right} != 1  ]\" \"select-pane -R\" \"run-shell '($MOVE right)  || exit 0' \""

# vim: ft=tmux
