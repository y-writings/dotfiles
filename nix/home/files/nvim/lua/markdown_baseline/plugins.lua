local vim = rawget(_G, 'vim')
return {
  {
    'EdenEast/nightfox.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme('duskfox')
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter',
    build = function()
      vim.cmd('TSInstallSync markdown markdown_inline')
    end,
    config = function()
      local ok, configs = pcall(require, 'nvim-treesitter.configs')
      if not ok then
        return
      end

      configs.setup({
        ensure_installed = { 'markdown', 'markdown_inline' },
        highlight = {
          enable = true,
        },
        indent = { enable = false },
      })
    end,
  },
  {
    'neovim/nvim-lspconfig',
    config = function()
      vim.lsp.config.markdown_oxide = {
        cmd = { 'markdown-oxide' },
        filetypes = { 'markdown' },
        root_markers = { '.obsidian', '.vault', '.git' },
      }
      vim.lsp.enable('markdown_oxide')
    end,
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    cmd = { 'RenderMarkdown' },
    ft = { 'markdown' },
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('render-markdown').setup({
        heading = {
          atx = false,
        },
        code = {
          conceal_delimiters = false,
          border = 'hide',
        },
      })
    end,
  },
  {
    'dkarter/bullets.vim',
    ft = { 'markdown' },
    init = function()
      vim.g.bullets_set_mappings = 1
    end,
  },
  {
    'tpope/vim-surround',
  },
  {
    'stevearc/conform.nvim',
    config = function()
      require('conform').setup({
        formatters_by_ft = { markdown = { 'prettier' } },
        formatters = {
          prettier = { prepend_args = { '--prose-wrap', 'always', '--print-width', '80' } },
        },
      })
    end,
  },
  {
    'mfussenegger/nvim-lint',
    config = function()
      local ok, lint = pcall(require, 'lint')
      if not ok then
        return
      end
      lint.linters_by_ft = { markdown = { 'markdownlint-cli2' } }
      local markdownlint = lint.linters['markdownlint-cli2']
      markdownlint.stdin = true
      markdownlint.args = { '-' }
      markdownlint.stream = 'stderr'
      markdownlint.ignore_exitcode = true
      markdownlint.parser = require('lint.parser').from_pattern(
        [[^[^:]+:(%d+):?(%d*)%s+(%S+)%s+(.*)]],
        { 'lnum', 'col', 'code', 'message' },
        nil,
        { ['source'] = 'markdownlint-cli2' }
      )
    end,
  },
  {
    'hedyhli/outline.nvim',
    cmd = { 'Outline' },
    config = function()
      require('outline').setup({})
    end,
  },
}
