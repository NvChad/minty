local M = {}

M.config = {
  huefy = { border = false, prompt = "   Enter color : " },
  shades = { border = true, prompt = "   Enter color : " },
}

M.setup = function(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

return M
