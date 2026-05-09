local M = {}

function M.setup()
  require('markdown_baseline.settings').setup()
  require('markdown_baseline.keymaps').setup()
end

M.setup()

return M
