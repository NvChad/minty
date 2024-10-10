local M = {}

M.config = {
  huefy = { border = false },
  shades = { border = true },
}

M.setup = function(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

return M
