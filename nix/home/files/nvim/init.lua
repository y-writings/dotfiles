local vim = rawget(_G, 'vim')

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.opt.clipboard:append('unnamedplus')

local function prepend_path(dir)
  if not dir or dir == "" then
    return
  end
  local path = vim.env.PATH or ""
  if not (":" .. path .. ":"):find(":" .. dir .. ":", 1, true) then
    vim.env.PATH = dir .. ":" .. path
  end
end

prepend_path("/run/current-system/sw/bin")
prepend_path(vim.fn.expand("$HOME/.nix-profile/bin"))
prepend_path(vim.fn.expand("/etc/profiles/per-user/$USER/bin"))

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
local uv = vim.uv or vim.loop
if not uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    error('Failed to clone lazy.nvim:\n' .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  spec = {
    { import = 'markdown_baseline.plugins' },
  },
  lockfile = vim.fn.stdpath('state') .. '/lazy-lock.json',
  checker = { enabled = false },
  change_detection = { enabled = false },
})

require('markdown_baseline')
