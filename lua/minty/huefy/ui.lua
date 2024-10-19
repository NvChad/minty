local api = vim.api
local v = require "minty.huefy.state"
local redraw = require("volt").redraw
local lighten = require("volt.color").change_hex_lightness
local change_hue = require("volt.color").change_hex_hue
local rgb2hex = require("volt.color").rgb2hex
local change_saturation = require("volt.color").change_hex_saturation
local ui = require "volt.ui"
local hex2complementary = require("volt.color").hex2complementary
local config = require("minty").config.huefy
local huefyapi = require "minty.huefy.api"
local g = vim.g

local M = {}

local redraw_all = function()
  redraw(v.tools_buf, "all")
  redraw(v.palette_buf, "all")
end

------------------------------- color blocks ----------------------------------------
local function gen_colors(hex, row, type)
  local blocks = {}
  local abc = type == "dark" and -1 or 12

  for i = 1, 12, 1 do
    local color = lighten(hex or v.new_hex, (abc - i) * row * 1.3)
    local hlgroup = "hue" .. i .. row .. (type or "")

    local block = {
      "   ",
      hlgroup,
      function()
        v.set_hex(color)
        redraw_all()
      end,
    }

    api.nvim_set_hl(v.paletteNS, hlgroup, { bg = color })

    table.insert(blocks, block)
  end

  return blocks
end

M.palettes = function()
  local blocks = {}

  for row = 1, 4, 1 do
    table.insert(blocks, 1, gen_colors(nil, row))
  end

  local lastcolor = api.nvim_get_hl(v.paletteNS, { name = blocks[#blocks][1][2] }).bg
  lastcolor = string.format("%06x", lastcolor)

  for row = 1, 5, 1 do
    table.insert(blocks, gen_colors(lastcolor, row, "dark"))
  end

  table.insert(blocks, 1, {})
  table.insert(blocks, {})
  return blocks
end

M.hue = function()
  local separator = { { string.rep("-", v.w_with_pad), "LineNr" } }
  local result = {}

  for i = 1, 36, 1 do
    local color = change_hue(v.new_hex, i * v.hue_intensity)
    local hlgroup = "huevarients" .. i

    local block = {
      " ",
      hlgroup,
      function()
        v.set_hex(color)
        redraw_all()
      end,
    }

    table.insert(result, block)
    api.nvim_set_hl(v.paletteNS, hlgroup, { bg = color })
  end

  return {
    {
      { "Hue Variants" },
      { string.rep(" ", 10) },

      {
        "",
        "Function",
        function()
          v.hue_intensity = v.hue_intensity + 1
          redraw(v.palette_buf, { "hue" })
        end,
      },

      { "  " },

      {
        "",
        "Comment",
        function()
          v.hue_intensity = v.hue_intensity - 1
          redraw(v.palette_buf, { "hue" })
        end,
      },

      { "  Step: " .. v.hue_intensity },
    },

    separator,

    result,
  }
end

local save_color = {
  click = huefyapi.save_color,
  hover = { id = "saved_color", redraw = "footer" },
}

M.footer = function()
  local col_len = 9

  local function gen_padding(n)
    return { string.rep(" ", n or 1) }
  end

  local space = gen_padding()
  local underline = { string.rep("-", col_len), "LineNr" }

  api.nvim_set_hl(v.paletteNS, "hex1", { fg = "#" .. v.hex })
  api.nvim_set_hl(v.paletteNS, "hex2", { fg = "#" .. v.new_hex })

  local borderhl = g.nvmark_hovered == "saved_color" and "Normal" or "LineNr"

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
      { " 󰆓 Save ", "Normal", save_color },
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
    config.border and {} or nil,
  }

  return results
end

---------------------------------- slider -------------------------------------------

M.rgb_slider = function()
  local rgb = v.sliders
  local lines = { config.border and {} or nil }
  local sliders_info = { { "r", "Red" }, { "g", "Green" }, { "b", "Blue" } }

  for _, val in ipairs(sliders_info) do
    local txt = val[1]:upper() .. "  "

    local mark = ui.slider.config {
      txt = txt,
      w = v.tools_with_pad,
      val = math.floor(rgb[val[1]]),
      hlon = "Ex" .. val[2],
      ratio_txt = true,
      actions = function()
        rgb[val[1]] = ui.slider.val(v.tools_with_pad, txt, v.xpad, { ratio = true })

        v.new_hex = rgb2hex(rgb.r, rgb.g, rgb.b):sub(2)
        redraw(v.tools_buf, { "rgb_slider", "suggested_colors" })
        redraw(v.palette_buf, "all")
      end,
    }

    table.insert(lines, mark)
  end

  return lines
end

M.saturation_slider = function()
  local handle_click = function(step)
    local mm = v.saturation_mode == "dim" and -1 or 1
    v.sliders.saturation = step or ui.slider.val(v.tools_with_pad, nil, v.xpad, { thumb = true })
    local color = change_saturation("#" .. v.hex, v.sliders.saturation * mm)
    v.set_hex(color)
    redraw(v.tools_buf, { "saturation_slider", "rgb_slider", "suggested_colors" })
    redraw(v.palette_buf, "all")
  end

  return {
    {},

    {
      { "󰌁  Saturation" },

      { string.rep(" ", 14) },

      ui.checkbox {
        txt = "Invert",
        active = g.nvmark_hovered == "invert_checkbox" or v.saturation_mode == "vibrant",
        actions = {
          click = function()
            v.saturation_mode = v.saturation_mode == "dim" and "vibrant" or "dim"
            handle_click(10)
          end,

          hover = { id = "invert_checkbox", redraw = "saturation_slider" },
        },
      },
    },

    ui.slider.config {
      w = v.tools_with_pad,
      val = v.sliders.saturation,
      hlon = "Normal",
      ratio_txt = false,
      thumb = true,
      actions = handle_click,
    },
  }
end

M.lightness_slider = function()
  local handle_click = function(step)
    local mm = v.lightness_mode == "dark" and -1 or 1
    v.sliders.lightness = step or ui.slider.val(v.tools_with_pad, nil, v.xpad, { thumb = true })
    local color = lighten("#" .. v.hex, v.sliders.lightness * mm)
    v.set_hex(color)
    redraw(v.tools_buf, { "lightness_slider", "rgb_slider", "suggested_colors" })
    redraw(v.palette_buf, "all")
  end

  return {
    {},

    {
      { "󰖨  Lightness" },

      { string.rep(" ", 15) },

      ui.checkbox {
        txt = "Darken",
        active = g.nvmark_hovered == "darken_checkbox" or v.lightness_mode == "dark",
        actions = {
          hover = { id = "darken_checkbox", redraw = "lightness_slider" },
          click = function()
            v.lightness_mode = v.lightness_mode == "dark" and "light" or "dark"
            handle_click(v.sliders.lightness)
          end,
        },
      },
    },

    ui.slider.config {
      w = v.tools_with_pad,
      val = v.sliders.lightness,
      hlon = "Normal",
      ratio_txt = false,
      thumb = true,
      actions = handle_click,
    },
  }
end

M.suggested_colors = function()
  local separator = { { string.rep("-", v.w_with_pad), "LineNr" } }
  local qty = 36
  local colors = hex2complementary(v.new_hex, qty)

  local line1 = {}
  local line2 = {}

  for i, color in ipairs(colors) do
    local hlgroup = "compcolor" .. i
    api.nvim_set_hl(v.toolsNS, hlgroup, { fg = color })

    local hover_id = "suggested" .. i
    local hovered = g.nvmark_hovered == hover_id

    local virt_text = {
      hovered and "" or "󱓻",
      hlgroup,
      {
        hover = { id = hover_id, redraw = "suggested_colors" },

        click = function()
          v.set_hex(color)
          redraw_all()
        end,
      },
    }

    local space = { " " }

    if i <= qty / 2 then
      table.insert(line1, virt_text)
      table.insert(line1, space)
    else
      table.insert(line2, virt_text)
      table.insert(line2, space)
    end
  end

  return {
    {},
    { { "󱥚  Complementary Colors" } },
    separator,

    line1,
    line2,

    config.border and {} or nil,
  }
end

return M
