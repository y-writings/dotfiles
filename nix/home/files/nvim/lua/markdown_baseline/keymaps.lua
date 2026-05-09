local vim = rawget(_G, 'vim')

local M = {}

function M.setup()
  vim.api.nvim_create_user_command('MarkdownFormat', function()
    local ok, conform = pcall(require, 'conform')
    if ok then
      conform.format({ bufnr = 0 })
    else
      vim.notify('conform.nvim not found', vim.log.levels.ERROR)
    end
  end, { desc = 'Format markdown buffer' })

  vim.api.nvim_create_user_command('MarkdownLint', function()
    local ok, lint = pcall(require, 'lint')
    if ok then
      lint.try_lint(nil, { cwd = vim.fn.expand('%:p:h') })
      vim.wait(5000, function()
        return #lint.get_running(0) == 0
      end, 100)
      -- Force a tick to allow scheduled callbacks to run
      vim.cmd('sleep 10m')
    else
      vim.notify('nvim-lint not found', vim.log.levels.ERROR)
    end
  end, { desc = 'Lint markdown buffer' })

  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'markdown',
    callback = function(ev)
      local opts = { buffer = ev.buf, silent = true }
      vim.keymap.set('n', '<leader>mf', '<cmd>MarkdownFormat<cr>', opts)
      vim.keymap.set('n', '<leader>ml', '<cmd>MarkdownLint<cr>', opts)
      vim.keymap.set('n', '<leader>mo', '<cmd>Outline<cr>', opts)
    end,
  })
end

return M
