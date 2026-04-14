-- plugin/sailor.lua
-- Entry-point shim. Guards against double-loading and applies default setup
-- so the plugin works out of the box.
-- Users who want to call require('sailor').setup(opts) with custom options
-- should set vim.g.sailor_no_default_setup = 1 before this file is loaded,
-- then call setup() themselves.

if vim.g.loaded_sailor then
  return
end
vim.g.loaded_sailor = 1

if not vim.g.sailor_no_default_setup then
  local ok, sailor = pcall(require, 'sailor')
  if ok then
    sailor.setup()
  end
end
