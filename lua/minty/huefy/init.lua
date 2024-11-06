local M = {}
local api = vim.api
local utils = require "minty.utils"

local v = require "minty.huefy.state"
local mark_state = require "volt.state"
local redraw = require("volt").redraw
local layout = require "minty.huefy.layout"
local hex2rgb_ratio = require("volt.color").hex2rgb_ratio

local volt = require "volt"
local volt_events = require "volt.events"

local map = vim.keymap.set
local huefyapi = require "minty.huefy.api"

v.paletteNS = api.nvim_create_namespace "Huefy"
v.inputNS = api.nvim_create_namespace "HuefyInput"
v.toolsNS = api.nvim_create_namespace "HuefyTools"

M.open = function()
  local oldwin = api.nvim_get_current_win()
  local config = require("minty").config.huefy

  local border = config.border
  v.xpad = border and 2 or 1

  v.gen_w()

  v.hex = utils.hex_on_cursor() or "61afef"
  v.new_hex = v.hex
  v.sliders.r, v.sliders.g, v.sliders.b = hex2rgb_ratio(v.new_hex)

  v.palette_buf = api.nvim_create_buf(false, true)
  v.tools_buf = api.nvim_create_buf(false, true)
  local input_buf = api.nvim_create_buf(false, true)

  volt.gen_data {
    { buf = v.palette_buf, layout = layout.palette, xpad = v.xpad, ns = v.paletteNS },
    { buf = v.tools_buf, layout = layout.tools, xpad = v.xpad, ns = v.paletteNS },
  }

  local h = mark_state[v.palette_buf].h

  -- handle fallback col | if less space is there for window
  local cur_pos = api.nvim_win_get_cursor(0)
  local win_w = api.nvim_win_get_width(0)
  local total_w = (v.w * 2) + 10
  local fallback_col

  if win_w - cur_pos[2] < total_w then
    local kekw = win_w - cur_pos[2] - total_w
    fallback_col = -(cur_pos[1] - kekw)
  end

  local win = api.nvim_open_win(v.palette_buf, true, {
    row = 1,
    col = fallback_col or 1,
    -- row = (vim.o.lines / 2) / 2,
    -- col = vim.o.columns / 5,
    width = v.w,
    height = h,
    relative = "cursor",
    style = "minimal",
    border = "single",
    title = { { " 󱥚  Color picker ", border and "lazyh1" or "ExBlack3bg" } },
    title_pos = "center",
  })

  local tools_h = h - (border and 3 or 4)

  local input_win = api.nvim_open_win(input_buf, true, {
    row = -1,
    col = (border and 2 or 3) + v.w,
    width = v.w,
    height = 1,
    relative = "win",
    win = win,
    style = "minimal",
    border = "single",
  })

  local tools_win = api.nvim_open_win(v.tools_buf, true, {
    row = (border and 2 or 3),
    col = -1,
    width = v.tools_w,
    height = tools_h,
    relative = "win",
    win = input_win,
    style = "minimal",
    border = "single",
  })

  api.nvim_win_set_hl_ns(win, v.paletteNS)
  api.nvim_win_set_hl_ns(input_win, v.inputNS)
  api.nvim_win_set_hl_ns(tools_win, v.toolsNS)

  if border then
    api.nvim_set_hl(v.paletteNS, "FloatBorder", { link = "Comment" })
    api.nvim_set_hl(v.toolsNS, "FloatBorder", { link = "Comment" })
  else
    api.nvim_set_hl(v.paletteNS, "FloatBorder", { link = "ExDarkBorder" })
    api.nvim_set_hl(v.paletteNS, "Normal", { link = "ExDarkBg" })
    api.nvim_set_hl(v.inputNS, "FloatBorder", { link = "ExBlack2border" })
    api.nvim_set_hl(v.inputNS, "Normal", { link = "ExBlack2Bg" })
    api.nvim_set_hl(v.toolsNS, "FloatBorder", { link = "Exblack2border" })
    api.nvim_set_hl(v.toolsNS, "Normal", { link = "ExBlack2Bg" })
  end

  api.nvim_set_current_win(win)
  api.nvim_buf_set_lines(input_buf, 0, -1, false, { "   Enter color : #" .. v.hex })

  volt.run(v.palette_buf, { h = h, w = v.w })
  volt.run(v.tools_buf, { h = tools_h, w = v.w })
  volt_events.add { v.palette_buf, v.tools_buf }

  ----------------- keymaps --------------------------
  -- redraw some sections on <cr>
  vim.keymap.set("i", "<cr>", function()
    local cur_line = api.nvim_get_current_line()
    v.hex = string.match(cur_line, "%w+$")
    v.set_hex("#" .. v.hex)
    redraw(v.palette_buf, "all")
    redraw(v.tools_buf, "all")
  end, { buffer = input_buf })

  volt.mappings {
    bufs = { v.palette_buf, input_buf, v.tools_buf },
    input_buf = input_buf,
    after_close = function()
      api.nvim_set_current_win(oldwin)
    end,
  }

  map("n", "<C-s>", huefyapi.save_color, { buffer = v.palette_buf })
  map("n", "<C-s>", huefyapi.save_color, { buffer = v.tools_buf })

  if config.mappings then
    config.mappings { v.palette_buf, v.tools_buf }
  end
end

return M
