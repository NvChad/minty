local M = {
  hex = "",
  ns = 0,
  xpad = 2,
  step = 10,
  intensity = 50,
  blocklen = 6,
  palette_cols = 6,
  mode = "Variants",
  close = nil,
  visible = true,

  config = {
    border = true,
  },
}

M.w = M.palette_cols * M.blocklen + (2 * M.xpad)
M.w_with_pad = M.w - (2 * M.xpad)

return M
