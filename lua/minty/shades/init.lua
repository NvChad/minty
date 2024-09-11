local M = {}
local api = vim.api
local utils = require "minty.utils"
local v = require "minty.shades.state"
local mark_state = require "volt.state"
local redraw = require("volt").redraw
local layout = require "minty.shades.layout"
local extmarks = require "volt"
local extmarks_events = require "volt.events"

v.ns = api.nvim_create_namespace "NvShades"

M.open = function()
  local oldwin = api.nvim_get_current_win()

  v.hex = utils.hex_on_cursor() or "61afef"
  v.new_hex = v.hex
  v.buf = api.nvim_create_buf(false, true)

  local input_buf = api.nvim_create_buf(false, true)

  extmarks.gen_data {
    { buf = v.buf, layout = layout, xpad = v.xpad, ns = v.ns },
  }

  local h = mark_state[v.buf].h

  local win = api.nvim_open_win(v.buf, true, {
    row = 1,
    col = 0,
    width = v.w,
    height = h,
    relative = "cursor",
    style = "minimal",
    border = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
    title = " 󱥚 Color Shades ",
    title_pos = "center",
  })

  api.nvim_open_win(input_buf, true, {
    row = h + 1,
    col = -1,
    width = v.w,
    height = 1,
    relative = "win",
    win = win,
    style = "minimal",
    border = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
  })

  api.nvim_buf_set_lines(input_buf, 0, -1, false, { "   Enter color : #" .. v.hex })

  api.nvim_win_set_hl_ns(win, v.ns)
  api.nvim_set_hl(v.ns, "FloatBorder", { link = "LineNr" })

  api.nvim_set_current_win(win)

  extmarks.run(v.buf, { h = h, w = v.w })
  extmarks_events.add(v.buf)

  ----------------- keymaps --------------------------
  -- redraw some sections on <cr>
  vim.keymap.set("i", "<cr>", function()
    local cur_line = api.nvim_get_current_line()
    v.hex = string.match(cur_line, "%w+$")
    v.new_hex = v.hex
    redraw(v.buf, { "palettes", "footer" })
  end, { buffer = input_buf })

  extmarks.mappings {
    bufs = { v.buf, input_buf },
    input_buf = input_buf,
    close_func_post = function()
      api.nvim_set_current_win(oldwin)
    end,
  }
end

M.toggle = function()
  extmarks.toggle_func(M.open, v.visible)
  v.visible = not v.visible
end

return M