local M = {}
local api = vim.api
local utils = require "minty.utils"

local v = require "minty.huefy.state"
local mark_state = require "volt.state"
local redraw = require("volt").redraw
local layout = require "minty.huefy.layout"
local hex2rgb_ratio = require("volt.color").hex2rgb_ratio

local extmarks = require "volt"
local extmarks_events = require "volt.events"

v.paletteNS = api.nvim_create_namespace "Huefy"
v.inputNS = api.nvim_create_namespace "HuefyInput"
v.toolsNS = api.nvim_create_namespace "HuefyTools"

M.open = function()
  local oldwin = api.nvim_get_current_win()

  v.hex = utils.hex_on_cursor() or "61afef"
  v.new_hex = v.hex
  v.sliders.r, v.sliders.g, v.sliders.b = hex2rgb_ratio(v.new_hex)

  v.palette_buf = api.nvim_create_buf(false, true)
  v.tools_buf = api.nvim_create_buf(false, true)
  local input_buf = api.nvim_create_buf(false, true)

  extmarks.gen_data {
    { buf = v.palette_buf, layout = layout.palette, xpad = v.xpad, ns = v.paletteNS },
    { buf = v.tools_buf, layout = layout.tools, xpad = v.xpad, ns = v.paletteNS },
  }

  local h = mark_state[v.palette_buf].h

  local win = api.nvim_open_win(v.palette_buf, true, {
    row = 1,
    col = 1,
    -- row = (vim.o.lines / 2) / 2,
    -- col = vim.o.columns / 5,
    width = v.w,
    height = h,
    relative = "cursor",
    style = "minimal",
    border = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
    title = {{" 󱥚  Color picker ", "ExHovered"}},
    title_pos = "center",
  })

  local tools_h = h - 4

  local input_win = api.nvim_open_win(input_buf, true, {
    row = -1,
    col = 3 + v.w,
    width = v.w,
    height = 1,
    relative = "win",
    win = win,
    style = "minimal",
    border = "single",
  })

  local tools_win = api.nvim_open_win(v.tools_buf, true, {
    row = 3,
    col = v.w + 3,
    width = v.tools_w,
    height = tools_h,
    relative = "win",
    win = win,
    style = "minimal",
    border = "single",
  })

  api.nvim_win_set_hl_ns(win, v.paletteNS)
  api.nvim_win_set_hl_ns(input_win, v.inputNS)
  api.nvim_win_set_hl_ns(tools_win, v.toolsNS)

  api.nvim_set_hl(v.paletteNS, "FloatBorder", { link = "ExDarkBorder" })
  api.nvim_set_hl(v.paletteNS, "Normal", { link = "ExDarkBg" })
  api.nvim_set_hl(v.inputNS, "FloatBorder", { link = "ExBlack2border" })
  api.nvim_set_hl(v.inputNS, "Normal", { link = "ExBlack2Bg" })
  api.nvim_set_hl(v.toolsNS, "FloatBorder", { link = "Exblack2border" })
  api.nvim_set_hl(v.toolsNS, "Normal", { link = "ExBlack2Bg" })

  api.nvim_set_current_win(win)
  api.nvim_buf_set_lines(input_buf, 0, -1, false, { "   Enter color : #" .. v.hex })

  extmarks.run(v.palette_buf, { h = h, w = v.w })
  extmarks.run(v.tools_buf, { h = tools_h, w = v.w })
  extmarks_events.add { v.palette_buf, v.tools_buf }

  ----------------- keymaps --------------------------
  -- redraw some sections on <cr>
  vim.keymap.set("i", "<cr>", function()
    local cur_line = api.nvim_get_current_line()
    v.hex = string.match(cur_line, "%w+$")
    v.set_hex("#" .. v.hex)
    redraw(v.palette_buf, "all")
    redraw(v.tools_buf, "all")
  end, { buffer = input_buf })

  extmarks.mappings {
    bufs = { v.palette_buf, input_buf, v.tools_buf },
    inputbuf = input_buf,
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
