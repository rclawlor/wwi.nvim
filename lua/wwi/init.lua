local M = {}


-- Imports
local config = require("wwi.config")
local history = require("wwi.history")


--- Setup function for the wwi.nvim plugin
---
--- @param opts table
function M.setup(opts)
    opts = opts or {}

    config.set_defaults(opts)

    vim.api.nvim_create_augroup(
        "wwi", { clear = true }
    )
    history.setup_autocmd()
end


return M
