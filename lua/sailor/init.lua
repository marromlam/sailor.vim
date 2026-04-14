local M = {}

-- ---------------------------------------------------------------------------
-- Section 1: Private state & constants
-- ---------------------------------------------------------------------------

local state = {
  kitty_is_last_pane = false,
  tmux_is_last_pane  = false,
}

-- vim direction → kitty/wezterm named direction
local kitty_mappings = { h = 'left', j = 'bottom', k = 'top', l = 'right' }

-- vim direction → tmux select-pane flag
local tmux_dir = { h = 'L', j = 'D', k = 'U', l = 'R' }

-- valid directions for M.navigate input validation
local valid_directions = { h = true, j = true, k = true, l = true }

local config = {} -- populated by setup()

-- ---------------------------------------------------------------------------
-- Section 2: Shell / tmux helpers
-- ---------------------------------------------------------------------------

local function vim_navigate(direction)
  local ok = pcall(vim.cmd, 'wincmd ' .. direction)
  return ok
end

-- direction: one of 'left', 'bottom', 'top', 'right'
local function native_term_command(direction)
  if os.getenv('WEZTERM_PANE') then
    local wez = { 'env', '-u', 'WEZTERM_UNIX_SOCKET', 'wezterm', 'cli' }
    local clients = vim.fn.system(vim.list_extend(vim.deepcopy(wez), { 'list-clients' }))
    local last_line
    for line in clients:gmatch('[^\r\n]+') do
      if line:match('%S') then last_line = line end
    end
    local pane_id = last_line and last_line:match('(%S+)%s*$')
    if not pane_id then return end
    vim.fn.system(vim.list_extend(vim.deepcopy(wez),
      { 'activate-pane-direction', '--pane-id', pane_id, direction }))
  elseif os.getenv('SSH_TTY') then
    local port = os.getenv('KITTY_PORT') or ''
    vim.fn.system({ 'kitty', '@', '--to=tcp:localhost:' .. port,
      'kitten', 'kittens/neighboring_window.py', direction })
  else
    vim.fn.system({ 'kitty', '@', 'kitten', 'kittens/neighboring_window.py', direction })
  end
end

local function tmux_or_tmate()
  local tmux_env = os.getenv('TMUX') or ''
  if tmux_env:find('tmate') then
    return 'tmate'
  end
  return 'tmux'
end

local function tmux_socket()
  local tmux_env = os.getenv('TMUX') or ''
  return tmux_env:match('^([^,]+)')
end

-- args: table of strings, e.g. { 'display-message', '-p', '#{window_zoomed_flag}' }
local function tmux_command(args)
  local cmd = vim.list_extend({ tmux_or_tmate(), '-S', tmux_socket() }, args)
  return vim.fn.system(cmd)
end

local function tmux_pane_is_zoomed()
  local result = tmux_command({ 'display-message', '-p', '#{window_zoomed_flag}' })
  return vim.trim(result) == '1'
end

local function should_forward_to_tmux(tmux_last_pane, at_tab_page_edge)
  if config.disable_when_zoomed and tmux_pane_is_zoomed() then
    return false
  end
  return tmux_last_pane or at_tab_page_edge
end

-- ---------------------------------------------------------------------------
-- Section 3: Navigation
-- ---------------------------------------------------------------------------

local function kitty_aware_navigate(direction)
  local nr = vim.fn.winnr()
  local kitty_last_pane = not vim_navigate(direction)
  local at_tab_page_edge = (vim.fn.winnr() == nr)

  if kitty_last_pane or at_tab_page_edge then
    native_term_command(kitty_mappings[direction])
    state.kitty_is_last_pane = true
  else
    state.kitty_is_last_pane = false
  end
end

local function tmux_aware_navigate(direction)
  local nr = vim.fn.winnr()
  local tmux_last_pane = false
  local ok = vim_navigate(direction)

  if ok then
    -- vim navigation succeeded; check if we actually moved
    local at_tab_page_edge = (vim.fn.winnr() == nr)
    if at_tab_page_edge then
      -- at the edge of vim within a tmux pane; forward to terminal
      tmux_last_pane = true
      native_term_command(kitty_mappings[direction])
      state.kitty_is_last_pane = true
    else
      state.kitty_is_last_pane = false
    end
  else
    -- vim navigation failed; we are at the vim boundary
    tmux_last_pane = true
  end

  -- recompute after the vim_navigate block (mirrors original VimScript)
  local at_tab_page_edge = (vim.fn.winnr() == nr)

  if should_forward_to_tmux(tmux_last_pane, at_tab_page_edge) then
    if config.save_on_switch == 1 then
      pcall(vim.cmd, 'update')
    elseif config.save_on_switch == 2 then
      pcall(vim.cmd, 'wall')
    end

    local args = { 'select-pane', '-t', os.getenv('TMUX_PANE') or '', '-' .. tmux_dir[direction] }
    if config.preserve_zoom then
      table.insert(args, '-Z')
    end

    tmux_command(args)
    state.tmux_is_last_pane = true
  else
    state.tmux_is_last_pane = false
  end
end

function M.navigate(direction)
  if not valid_directions[direction] then
    vim.notify("sailor: invalid direction '" .. tostring(direction) .. "' (expected h/j/k/l)", vim.log.levels.ERROR)
    return
  end
  local tmux_env = os.getenv('TMUX')
  if tmux_env and tmux_env ~= '' then
    tmux_aware_navigate(direction)
  else
    kitty_aware_navigate(direction)
  end
end

-- ---------------------------------------------------------------------------
-- Section 4: Public API
-- ---------------------------------------------------------------------------

function M.setup(opts)
  config = vim.tbl_deep_extend('force', {
    no_mappings           = false,
    save_on_switch        = 1,
    disable_when_zoomed   = false,
    preserve_zoom         = false,
  }, opts or {})

  local augroup = vim.api.nvim_create_augroup('Sailor', { clear = true })
  vim.api.nvim_create_autocmd('WinEnter', {
    group    = augroup,
    callback = function()
      state.kitty_is_last_pane = false
      state.tmux_is_last_pane  = false
    end,
  })

  local commands = {
    AwesomeNavigateLeft  = 'h',
    AwesomeNavigateRight = 'l',
    AwesomeNavigateUp    = 'k',
    AwesomeNavigateDown  = 'j',
  }
  for name, dir in pairs(commands) do
    vim.api.nvim_create_user_command(name, function()
      M.navigate(dir)
    end, {})
  end

  if not config.no_mappings then
    local o = { silent = true, noremap = true }
    vim.keymap.set('n', '<C-h>', '<Cmd>AwesomeNavigateLeft<CR>',  o)
    vim.keymap.set('n', '<C-j>', '<Cmd>AwesomeNavigateDown<CR>',  o)
    vim.keymap.set('n', '<C-k>', '<Cmd>AwesomeNavigateUp<CR>',    o)
    vim.keymap.set('n', '<C-l>', '<Cmd>AwesomeNavigateRight<CR>', o)
  end
end

return M
