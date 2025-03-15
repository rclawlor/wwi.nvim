local M = {}


-- Imports
local config = require("wwi.config")
local utils = require("wwi.utils")

-- Variables
M.files = {}


--- Setup autocommand to track file history
function M.setup_autocmd()
    vim.api.nvim_create_autocmd(
        { "BufEnter" },
        {
            callback = function()
                local path = vim.api.nvim_buf_get_name(0)
                M.append_file(path)
            end
        }
    )
end


--- Add file to recent files list
---
--- @param file string file to add
function M.append_file(file)
    if utils.file_exists(file) then
        -- Find index of file
        local f_idx = nil
        for f, idx in pairs(M.files) do
            if f == file then
                f_idx = idx
                break
            end
        end

        for f, idx in pairs(M.files) do
            if f_idx == nil then
                if idx + 1 > config.opts.files then
                    M.files[f] = nil
                else
                    M.files[f] = idx + 1
                end
            else
                if idx < f_idx then
                    M.files[f] = idx + 1
                end
            end
        end

        M.files[file] = 1
    end
end


return M
