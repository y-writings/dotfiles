local vim = rawget(_G, 'vim')

local M = {}

function M.setup()
  vim.opt.number = true
  vim.opt.relativenumber = true
  vim.opt.mouse = 'a'

  if vim.fn.has('gui_running') == 1 or vim.g.neovide then
    vim.opt.guifont = 'Cascadia Code NF:h14'
  end

  vim.opt.ignorecase = true
  vim.opt.smartcase = true

  vim.opt.updatetime = 250
  vim.opt.signcolumn = 'yes'
  vim.opt.splitright = true
  vim.opt.splitbelow = true

  local group = vim.api.nvim_create_augroup('MarkdownBaselineMarkdown', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = 'markdown',
    callback = function()
      vim.opt_local.wrap = true
      vim.opt_local.linebreak = true
      vim.opt_local.breakindent = true
      vim.opt_local.conceallevel = 2
    end,
  })
end

return M
