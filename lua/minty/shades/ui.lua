local api = vim.api
local v = require "minty.shades.state"
local redraw = require("volt").redraw
local ui = require "volt.ui"
local config = require("minty").config.shades
local shadesapi  = require("minty.shades.api")
local g = vim.g

local M = {}

M.tabs = function()
  local modes = { "Variants", "Saturation", "Hues" }
  local result = {}

  for _, name in ipairs(modes) do
    local hover_name = "tabs_checkbox" .. name

    local mark = ui.checkbox {
      txt = name,
      active = g.nvmark_hovered == hover_name or v.mode == name,
      actions = {
        hover = { id = hover_name, redraw = "tabs" },

        click = function()
          v.mode = name
          redraw(v.buf, { "tabs", "palettes" })
        end,
      },
    }

    table.insert(result, mark)
    table.insert(result, { "  " })
  end

  return {
    {},
    result,
    { { string.rep("-", v.w_with_pad), "LineNr" } },
  }
end

------------------------------- color blocks ----------------------------------------
local color_funcs = {
  Variants = require("volt.color").change_hex_lightness,
  Saturation = require("volt.color").change_hex_saturation,
  Hues = require("volt.color").change_hex_hue,
}

M.palettes = function()
  local intensity = math.floor(v.intensity / 10)
  local gen_color = color_funcs[v.mode]
  local blockstr = string.rep(" ", v.blocklen)

  local light_blocks = {}
  local dark_blocks = {}

  for i = 1, v.palette_cols, 1 do
    local dark = gen_color(v.hex, -1 * (i - 1) * intensity)
    local light = gen_color(v.hex, (i - 1) * intensity)
    local dark_hl = "hue" .. i .. "dark"
    local light_hl = "hue" .. i .. "light"

    api.nvim_set_hl(v.ns, dark_hl, { bg = dark })
    api.nvim_set_hl(v.ns, light_hl, { bg = light })

    local dark_block = {
      blockstr,
      dark_hl,
      function()
        v.new_hex = dark:sub(2)
        redraw(v.buf, { "footer" })
      end,
    }

    local light_block = {
      blockstr,
      light_hl,
      function()
        v.new_hex = light:sub(2)
        redraw(v.buf, { "footer" })
      end,
    }

    table.insert(light_blocks, light_block)
    table.insert(dark_blocks, 1, dark_block)
  end

  return { light_blocks, light_blocks, dark_blocks, dark_blocks }
end

-------------------------- intensity status & column toggler -----------------------------------
local update_palette_cols = function(n)
  v.blocklen = n == 12 and 3 or 6
  v.palette_cols = n
  redraw(v.buf, { "palettes", "intensity" })
end

---------------------------------- intensity -------------------------------------------
M.intensity = function()
  local intensity = math.floor(v.intensity / 10)
  return {
    {},

    {
      { "Intensity : " .. intensity .. (intensity == 10 and "" or " ") },
      { "         " },

      {
        "",
        v.palette_cols == 12 and "Function" or "LineNr",
        function()
          update_palette_cols(12)
        end,
      },

      { "  " },

      {
        "",
        v.palette_cols == 6 and "Function" or "LineNr",
        function()
          update_palette_cols(6)
        end,
      },

      { "  Columns" },
    },

    ui.slider.config {
      w = v.w_with_pad,
      val = v.intensity,
      hlon = "ExRed",
      ratio_txt = false,
      actions = function()
        v.intensity = ui.slider.val(v.w_with_pad, nil, v.xpad)
        redraw(v.buf, { "intensity", "palettes" })
      end,
    },
  }
end

local save_color = {
  click = shadesapi.save_color,
  hover = { id = "savedcolor", redraw = "footer" },
}

M.footer = function()
  local col_len = 9

  local function gen_padding(n)
    return { string.rep(" ", n or 1) }
  end

  local space = gen_padding()
  local underline = { string.rep("-", col_len), "LineNr" }

  api.nvim_set_hl(v.ns, "hex1", { fg = "#" .. v.hex })
  api.nvim_set_hl(v.ns, "hex2", { fg = "#" .. v.new_hex })

  local borderhl = g.nvmark_hovered == "savedcolor" and "Function" or "LineNr"

  local results = {
    {},
    {
      { "Old Color" },
      space,
      space,
      { "New Color" },
      gen_padding(6),
      { "┌" .. string.rep("─", 8) .. "┐", borderhl, save_color },
    },

    {
      underline,
      space,
      space,
      underline,
      gen_padding(6),
      { "│", borderhl, save_color },
      { " 󰆓 Save ", "Function", save_color },
      { "│", borderhl, save_color },
    },

    {
      { "󱓻 ", "hex1" },
      { "#" .. v.hex },
      space,
      space,
      { "󱓻 ", "hex2" },
      { "#" .. v.new_hex },
      gen_padding(6),
      { "└" .. string.rep("─", 8) .. "┘", borderhl, save_color },
    },
    (config.border and {} or nil),
  }

  return results
end

return M
