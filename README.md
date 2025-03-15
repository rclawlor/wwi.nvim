# wwi.nvim

![lua workflow](https://github.com/rclawlor/wwi.nvim/actions/workflows/lua.yml/badge.svg)

**W**here **W**as **I** - quickly navigate through recently opened files.

## Getting started
### Installation
#### lazy.nvim
```lua
-- plugins/wwi.lua:
return {
    "rclawlor/wwi.nvim",
    config = require("wwi").setup({})
}
```

## Usage
Use `:WhereWasI` to show a popup menu listing your recent files, which can be scrolled through using `j` and `k` (or &#8593; and &#8595;). Selecting a file with the `ENTER` key will open it for editing in a new buffer!

<div align="center">
  <video src=https://github.com/user-attachments/assets/8016ac9c-764c-4f19-9c11-b85b2723266a/>
</div>

To remap the functions to something more convenient, you can use the following:
```lua
vim.api.nvim_set_keymap("n", "<C-h>", "<cmd>WhereWasI<CR>", {noremap = true, silent = true})
```

## Customisation
This section explains the available options for configuring `wwi.nvim`

### Setup function
```lua
require("wwi").setup({
    --- Number of files to show
    files = 5,
    --- Padding left/right of entries
    padding = 2,
    --- Keymaps to close floating window
    close_keymaps = {
        "q",
        "<C-c>",
        "<Esc>"
    }
})
```
