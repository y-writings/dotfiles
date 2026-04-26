local vim = rawget(_G, 'vim')

local M = {}

local function set_markdown_heading_highlights()
  local levels = {
    { capture = '@markup.heading.1.markdown', color = '#f0c674' },
    { capture = '@markup.heading.2.markdown', color = '#e38b8b' },
    { capture = '@markup.heading.3.markdown', color = '#c6a0f6' },
    { capture = '@markup.heading.4.markdown', color = '#7dcfff' },
    { capture = '@markup.heading.5.markdown', color = '#8bd5ca' },
    { capture = '@markup.heading.6.markdown', color = '#a0a8c0' },
  }

  for _, level in ipairs(levels) do
    vim.api.nvim_set_hl(0, level.capture, { fg = level.color, bold = true })
  end
end

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

  set_markdown_heading_highlights()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = group,
    callback = set_markdown_heading_highlights,
  })
end

return M
