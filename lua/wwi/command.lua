local M = {}

-- Imports
local utils = require("wwi.utils")
local config = require("wwi.config")

-- Variables
LINE = 1
LINE_MARK = nil


--- Closes the preview window
---
---@param win_id integer ID of floating window
---@param buf_ids table|nil optional list of ignored buffers
local function close_preview_window(win_id, buf_ids)
    vim.schedule(
        function()
            -- exit if we are in one of ignored buffers
            if buf_ids and vim.list_contains(buf_ids, vim.api.nvim_get_current_buf()) then
                return
            end

            local augroup = "floating_window_" .. win_id
            pcall(vim.api.nvim_del_augroup_by_name, augroup)
            pcall(vim.api.nvim_win_close, win_id, true)
        end
    )
end


--- Creates autocommand to highlight current line
---
--- @param win_id integer ID of floating window
--- @param buf_id integer ID of floating buffer
local function highlight_line_autocmd(win_id, buf_id, ns_id, width)
    vim.api.nvim_create_augroup(
        "highlight_line_" .. win_id,
        {
            clear = true
        }
    )

    vim.api.nvim_create_autocmd(
        { "CursorMoved" },
        {
            callback = function()
                local pos = vim.fn.getpos(".")
                if LINE_MARK == nil then
                    LINE_MARK = vim.api.nvim_buf_set_extmark(
                        buf_id, ns_id, LINE - 1, 0, {hl_group = "SignColumn", end_col = width}
                    )
                else
                    LINE_MARK = vim.api.nvim_buf_set_extmark(
                        buf_id, ns_id, LINE - 1, 0, {id = LINE_MARK, hl_group = "SignColumn", end_col = width}
                    )
                end
                LINE = pos[2]
                LINE_MARK = vim.api.nvim_buf_set_extmark(
                    buf_id, ns_id, LINE - 1, 0, {id = LINE_MARK, hl_group = "TermCursor", end_col = width}
                )
            end
        }
    )
end


--- Configures floating window and sets up autocommand
---
--- @param win_id integer ID of floating window
--- @param buf_id integer ID of floating buffer
local function configure_floating_window(win_id, buf_id, ns_id, width)
    -- Disable folding on current window
    vim.wo[win_id].foldenable = false

    vim.bo[buf_id].bufhidden = "wipe"

    vim.api.nvim_buf_set_keymap(
        buf_id,
        'n',
        'q',
        '<cmd>cclose<cr>',
        { silent = true, noremap = true, nowait = true }
    )

    highlight_line_autocmd(win_id, buf_id, ns_id, width)
end


--- Generate a list
function M.where_was_i()
    local cwd = vim.fn.getcwd()
    local files = vim.v.oldfiles
    local filenames = {}
    local file = 1

    local padding = string.rep(" ", config.opts.padding)
    local max_width = 1
    for idx = 1, config.opts.files + 1, 1 do
        local filename = files[idx]
        if utils.file_exists(filename) then
            if filename:find(cwd) == 1 then
                local concat_filename = file .. " " .. filename:gsub(cwd .. "/", "")
                filenames[file] = concat_filename
                max_width = math.max(max_width, #filenames[file])
                file = file + 1
            end
        end
    end

    for k, v in pairs(filenames) do
        filenames[k] = padding .. string.format("%-" .. max_width .. "s", v) .. padding
    end

    local viewport_width = vim.api.nvim_win_get_width(0)
    local viewport_height = vim.api.nvim_win_get_height(0)

    local width = max_width + 2 * config.opts.padding
    local height = file - 1

    local row = math.floor((viewport_height - height) / 2)
    local col = math.floor((viewport_width - width) / 2)

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, #filenames, false, filenames)
    local win_opts = {
        width = width,
        height = height,
        style = "minimal",
        relative = "win",
        row = row,
        col = col,
        border = "rounded",
        title = "Where Was I",
        title_pos = "center"
    }
    local win = vim.api.nvim_open_win(buf, true, win_opts)
    local ns_id = vim.api.nvim_create_namespace("wherewasi")
    vim.api.nvim_win_set_hl_ns(win, ns_id)
    configure_floating_window(win, buf, ns_id, width)
end

return M
