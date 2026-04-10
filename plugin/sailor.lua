-- plugin/sailor.lua
-- Thin entry-point shim. Guards against double-loading.
-- Users must call require('sailor').setup(opts) in their config.

if vim.g.loaded_sailor then
  return
end
vim.g.loaded_sailor = 1
