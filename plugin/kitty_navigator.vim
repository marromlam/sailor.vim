" Maps <C-h/j/k/l> to switch vim splits in the given direction. If there are
" no more windows in that direction, forwards the operation to kitty.

" Check if loaded, else skip
if exists("g:loaded_sailor") || &cp || v:version < 700
  " echo "Sailor is already loaded"
  finish
endif


" set some constants {{{

if !exists("g:sailor_no_mappings")
  let g:sailor_no_mappings = 0
endif

if !exists("g:sailor_save_on_switch")
  let g:sailor_save_on_switch = 1
endif

if !exists("g:sailor_disable_when_zoomed")
  let g:sailor_disable_when_zoomed = 0
endif

if !exists("g:sailor_preserve_zoom")
  let g:sailor_preserve_zoom = 0
endif

" }}}


" navigation function inside vim
function! s:VimNavigate(direction)
  try
    execute 'wincmd ' . a:direction
    return 0
  catch
    echohl ErrorMsg | echo 'E11: Invalid in command-line window; <CR> executes, CTRL-C quits: wincmd k' | echohl None
    return 1
  endtry
endfunction

" remove these in the future
command! VimNavigateLeft     call s:VimNavigate('h')
command! VimNavigateRight    call s:VimNavigate('l')
command! VimNavigateUp       call s:VimNavigate('k')
command! VimNavigateDown     call s:VimNavigate('j')


function! s:KittyCommand(args)
  " this is not needed in vim but in neovim it is!!
  if empty($SSH_TTY)
    let cmd = 'kitty @ ' . a:args
    " echo 'not in ssh'
  else
    let cmd = 'kitty @ --to=tcp:localhost:' . $KITTY_PORT . ' ' . a:args
    " echo 'in ssh'
  endif
  " let cmd = 'kitty @ ' . a:args
  return system(cmd)
endfunction

let s:kitty_mappings = {
\   "h": "left",
\   "j": "bottom",
\   "k": "top",
\   "l": "right"
\ }

if empty($TMUX)
  " echo "this is kitty"
  " then we just map to Kitty stuff  {{{

  " define the commands, in this case they are from kitty
  command! AwesomeNavigateLeft     call s:KittyAwareNavigate('h')
  command! AwesomeNavigateDown     call s:KittyAwareNavigate('j')
  command! AwesomeNavigateUp       call s:KittyAwareNavigate('k')
  command! AwesomeNavigateRight    call s:KittyAwareNavigate('l')

  let s:kitty_is_last_pane = 0

  augroup SailorKitty
    au!
    autocmd WinEnter * let s:kitty_is_last_pane = 0
  augroup END

  function! s:KittyAwareNavigate(direction)
    let nr = winnr()
    let kitty_last_pane = (a:direction == 'p' && s:kitty_is_last_pane)
    if (!kitty_last_pane)
      let ok = s:VimNavigate(a:direction)
      if (ok)
        " echo "good"
      else
        " echo "wrong"
        " then actually it is the last pane
        let kitty_last_pane = 1
      endif
    endif
    let at_tab_page_edge = (nr == winnr())
  
    if kitty_last_pane || at_tab_page_edge
      let args = 'kitten kittens/neighboring_window.py' . ' ' . s:kitty_mappings[a:direction]
      silent call s:KittyCommand(args)
      let s:kitty_is_last_pane = 1
    else
      let s:kitty_is_last_pane = 0
    endif
  endfunction
  " }}}
else
  " echo "this is within tmux"
  " then we just map to tmux stuff  {{{

  " define the commands, in this case they are from tmux
  command! AwesomeNavigateLeft     call s:TmuxAwareNavigate('h')
  command! AwesomeNavigateDown     call s:TmuxAwareNavigate('j')
  command! AwesomeNavigateUp       call s:TmuxAwareNavigate('k')
  command! AwesomeNavigateRight    call s:TmuxAwareNavigate('l')
  " command! AwesomeNavigatePrevious call s:TmuxAwareNavigate('p')

  function! s:TmuxOrTmateExecutable()
    return (match($TMUX, 'tmate') != -1 ? 'tmate' : 'tmux')
  endfunction

  function! s:TmuxVimPaneIsZoomed()
    return s:TmuxCommand("display-message -p '#{window_zoomed_flag}'") == 1
  endfunction

  function! s:TmuxSocket()
    " The socket path is the first value in the comma-separated list of $TMUX.
    return split($TMUX, ',')[0]
  endfunction

  function! s:TmuxCommand(args)
    let cmd = s:TmuxOrTmateExecutable() . ' -S ' . s:TmuxSocket() . ' ' . a:args
    let l:x=&shellcmdflag
    let &shellcmdflag='-c'
    let retval=system(cmd)
    let &shellcmdflag=l:x
    return retval
  endfunction

  function! s:TmuxNavigatorProcessList()
    echo s:TmuxCommand("run-shell 'ps -o state= -o comm= -t ''''#{pane_tty}'''''")
  endfunction
  command! TmuxNavigatorProcessList call s:TmuxNavigatorProcessList()

  let s:tmux_is_last_pane = 0
  augroup SailorTmux
    au!
    autocmd WinEnter * let s:tmux_is_last_pane = 0
  augroup END

  function! s:NeedsVitalityRedraw()
    return exists('g:loaded_vitality') && v:version < 704 && !has("patch481")
  endfunction

  function! s:ShouldForwardNavigationBackToTmux(tmux_last_pane, at_tab_page_edge)
    if g:sailor_disable_when_zoomed && s:TmuxVimPaneIsZoomed()
      return 0
    endif
    return a:tmux_last_pane || a:at_tab_page_edge
  endfunction

  function! s:TmuxAwareNavigate(direction)
    let nr = winnr()
    let tmux_last_pane = (a:direction == 'p' && s:tmux_is_last_pane)
    " let tmux_last_pane = 1
    if !tmux_last_pane
      let ok = s:VimNavigate(a:direction)
      if !(ok)
        " echo "we just moved"
        let at_tab_page_edge = (nr == winnr())
        if (at_tab_page_edge)
          " we need to fallback to kitty navigation
          " TODO: this is a bit hacky, but it seems to work
          "       we should check it works always
          " echo "ha! so this is the last pane"
          let tmux_last_pane = 1
          let args = 'kitten kittens/neighboring_window.py' . ' ' . s:kitty_mappings[a:direction]
          silent call s:KittyCommand(args)
          let s:kitty_is_last_pane = 1
        else
          " echo "ok, we are done"
          let s:kitty_is_last_pane = 0
        endif
      else
        " echo "we are at the edge of vim"
        " then actually it is the last pane
        let tmux_last_pane = 1
      endif
    endif
    let at_tab_page_edge = (nr == winnr())
    " Forward the switch panes command to tmux if:
    " a) we're toggling between the last tmux pane;
    " b) we tried switching windows in vim but it didn't have effect.
    if s:ShouldForwardNavigationBackToTmux(tmux_last_pane, at_tab_page_edge)

      if g:sailor_save_on_switch == 1
        try
          update " save the active buffer. See :help update
        catch /^Vim\%((\a\+)\)\=:E32/ " catches the no file name error
        endtry
      elseif g:sailor_save_on_switch == 2
        try
          wall " save all the buffers. See :help wall
        catch /^Vim\%((\a\+)\)\=:E141/ " catches the no file name error
        endtry
      endif

      let args = 'select-pane -t ' . shellescape($TMUX_PANE) . ' -' . tr(a:direction, 'phjkl', 'lLDUR')
      if g:sailor_preserve_zoom == 1
        let l:args .= ' -Z'
      endif

      silent call s:TmuxCommand(args)

      if s:NeedsVitalityRedraw()
        redraw!
      endif

      let s:tmux_is_last_pane = 1

    else
      let s:tmux_is_last_pane = 0
    endif
  endfunction
  " }}}
endif


if !(g:sailor_no_mappings)
  nnoremap <silent> <c-h> :AwesomeNavigateLeft<cr>
  nnoremap <silent> <c-j> :AwesomeNavigateDown<cr>
  nnoremap <silent> <c-k> :AwesomeNavigateUp<cr>
  nnoremap <silent> <c-l> :AwesomeNavigateRight<cr>
  " this is just for debugging
  " nnoremap <c-h> :AwesomeNavigateLeft<cr>
  " nnoremap <c-j> :AwesomeNavigateDown<cr>
  " nnoremap <c-k> :AwesomeNavigateUp<cr>
  " nnoremap <c-l> :AwesomeNavigateRight<cr>
endif
let g:loaded_sailor = 1


" vim: ft=vim fdm=marker
