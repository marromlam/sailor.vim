Sailor.vim
==========

Sailor.vim is a (n)vim and tmux plugin which allows a seamless navigation between
kitty windows, tmux panes and (n)vim buffers.


Use cases
---------

Locally all the craziest things should work. This means you should be able to 
sailor between any sort of kitty/tmux/nvim split nomatter its nature.
Let's try to illustrate it:
```
+ ---------------------------- + ------------------------ +
| kitty window                 | kitty window             |
|                              |                          |
|   + ------- tmux ------- +   |                          |
|   |                      |   |                          |
|   |   + --- nvim --- +   |   |                          |
|   |   |              |   |   |                          |
|   |   | buffer       |   |   |                          |
|   |   |              |   |   |                          |
|   |   + ------------ +   |   |                          |
|   |                      |   |                          |
|   + -------------------- +   + ------------------------ +
|   |                      |   |                          |
|   | tmux pane            |   |   + ----- nvim ----- +   |
|   |                      |   |   |                  |   |
|   |                      |   |   | buffer           |   |
|   |                      |   |   |                  |   |
|   + -------------------- +   |   + ---------------- +   |
|                              |                          |
+ ---------------------------- + ------------------------ +
```




Usage
-----

This plugin provides the following mappings which allow you to move between
vim splits, tmux panes, and kitty windows seamlessly.

- `<ctrl-h>` => Left
- `<ctrl-j>` => Down
- `<ctrl-k>` => Up
- `<ctrl-l>` => Right


Installation
------------

The `install.sh` script will create some symbolic links for kitty so it is
straightforward to get it running. You will need to restart kitty so all 
the configuration works fine. This file runs after the vim/nvim plugin is
installed.

### Requirements

- This requires kitty version higher than 0.13.1 and lower than 0.24.x.
- Requires newer version of tmux version higher than 2.7.


### Editor: vim/nvim.

Use your favorite plugin manager (`packer.nvim` in the example) and add this
repository to your plugin list
```lua
packer.use {
  "marromlam/sailor.vim",
  run = "./install.sh"
}
```

### kitty.

When installing the vim/nvim plugin, the installer is going to create 
 `pass_keys.py` and `neighboring_window.py` kittens into
 `~/.config/kitty/kittens`. We still need to configure two more things:

1. Add the following to your `~/.config/kitty/kitty.conf` file:

```sh
map ctrl+j kitten kittens/pass_keys.py bottom ctrl+j
map ctrl+k kitten kittens/pass_keys.py top    ctrl+k
map ctrl+h kitten kittens/pass_keys.py left   ctrl+h
map ctrl+l kitten kittens/pass_keys.py right  ctrl+l
```

2. Enable kitty `allow_remote_control` and `listen_on` option:

Set it on the `~/.config/kitty/kitty.conf` file:

```conf
allow_remote_control yes
listen_on unix:/tmp/mykitty
```

**OR**

Start kitty with the `listen_on` option so that vim can send commands to it.

```
kitty -o allow_remote_control=yes --listen-on unix:/tmp/mykitty
```

The listening address can be customized in your `.vimrc` or `init.lua` by setting
```lua
vim.g.kitty_navigator_listening_on_address = 'unix:/tmp/mykitty'
```.

### tmux.

If you're using [TPM](https://github.com/tmux-plugins/tpm), 
just add this snippet to your tmux.conf:

```conf
set -g @plugin 'marromlam/sailor.vim'
```

And update your tmux session, tipically `prefix`+`I`.
If you do not want to ue TPM, then you should just copy-paste
the `.tmux` file to your `tmux.conf` file.


SSH Compatibility
-----------------

With the settings above, navigation should work well locally. But if you need
kitty-tmux navigation also work through ssh, follow steps below:

1. Install kitty on your remote machine, here I show how to do it in 
linux using linuxbrew:
[How To](https://sw.kovidgoyal.net/kitty/binary.html?highlight=install).
```bash
wget https://github.com/kovidgoyal/kitty/releases/download/v0.20.3/kitty-0.20.3-x86_64.txz -O kitty.txz
mkdir $HOMEBREW_PREFIX/Cellar/kitty
tar xf kitty.txz -C $HOMEBREW_PREFIX/Cellar/kitty
ln -sf $HOMEBREW_PREFIX/Cellar/kitty/bin/kitty $HOMEBREW_PREFIX/bin
rm kitty.txz
```
With kitty installed on your remote system and remote control enabled, your
should be able to use remote control from ssh. But because of reasons explained
[here](https://github.com/kovidgoyal/kitty/issues/2338), it won't work from
inside tmux. So we're going to need some workarounds.

2. Set remote port forwarding when using SSH.

```sh
ssh -R 50000:${KITTY_LISTEN_ON#*:} user@host
```

The remote TCP port 50000 can be changed to anything depending on your needs.

You can put it as an alias on your shell rc file so you don't type it all the time.

```sh
alias ssh='ssh -R 50000:${KITTY_LISTEN_ON#*:}'
```

3. Add the following snippet to your remote machine's `.bashrc` or something similar on other shell:

```sh
# Source kitty binary
export PATH=$PATH:~/.local/kitty.app/bin/

# Set KITTY_PORT env variable
if [[ $SSH_TTY ]] && ! [ -n "$TMUX" ]; then
  export KITTY_PORT=`kitty @ ls 2>/dev/null | grep "[0-9]:/tmp/mykitty" | head -n 1 | cut -d : -f 1 | cut -d \" -f 2`
fi

# Kitty Terminal Navigation
bind -x '"\C-h": kitty @ kitten neighboring_window.py left'
bind -x '"\C-j": kitty @ kitten neighboring_window.py top'
bind -x '"\C-k": kitty @ kitten neighboring_window.py bottom'
bind -x '"\C-l": kitty @ kitten neighboring_window.py right'
```

  **Explanation**:
- Source kitty path so the binary can be called from anywhere
- Set the KITTY_PORT environment variable automatically from the foreground process that call ssh.
- Set terminal key binding for changing kitty window when not using tmux

4. Don't forget to install the tmux plugin on your remote system also. And copy `neighboring_window.py` to your remote machine ~/.config/kitty directory.


Ack
---

This plugin is a fork from [vim-kitty-navigator](https://github.com/knubie/vim-kitty-navigator) extending it's capabilities to also work with tmux pane navigation. The aim is to make navigation between Kitty windows, tmux panes, and vim splits seamless. With some extra configuration, kitty-tmux navigation works even through SSH!

