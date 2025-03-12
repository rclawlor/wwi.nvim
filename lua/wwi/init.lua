local M = {}


-- Imports
local config = require("wwi.config")


--- Setup function for the wwi.nvim plugin
---
--- @param opts table
function M.setup(opts)
    opts = opts or {}

    config.set_defaults(opts)
end


return M
