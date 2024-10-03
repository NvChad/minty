# Minty

Beautifully crafted color tools for Neovim
 
![shades](https://github.com/user-attachments/assets/d499748b-d9c8-4a92-89ba-bfce1814c275)
![huefy](https://github.com/user-attachments/assets/21f2c23d-94c6-4ccf-a0d0-ddf91f6bb5c1)

## Install

```lua
{ "nvchad/volt", lazy = true },
{ "nvchad/minty", lazy = true }

-- or users that have lazy=true by default :D
"nvchad/volt",
"nvchad/minty"
```

## Usage

```lua
require("minty.huefy").open()
require("minty.shades").open()

-- For border or without border
require("minty.huefy").open( { border = true } )
-- add border=false for flat look on shades window
```
## Mappings

- `<Ctrl> + t` : cycle through windows
- `<Tab>` or `<S-Tab>` : cycle through clickables in current window
