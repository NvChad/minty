local M = {}
local api = vim.api
local lighten_hex = require("volt.color").change_hex_lightness

M.hex_on_cursor = function()
  local hex = vim.fn.expand "<cword>"

  if hex:match "^%x%x%x%x%x%x$" then
    return hex
  end
end

-- lightens hex color under cursor, negative arg will darken
M.lighten_on_cursor = function(n)
  local hex = M.hex_on_cursor()

  if hex:match "^%x%x%x%x%x%x$" then
    local line = api.nvim_get_current_line()
    local new_hex = lighten_hex("#" .. hex, n)
    line = line:gsub(hex, new_hex:sub(2))
    api.nvim_set_current_line(line)
  end
end

return M
