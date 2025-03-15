local M = {}

-- Imports
local config = require("wwi.config")
local history = require("wwi.history")

-- Variables
M.line = 1
M.line_mark = nil
M.cwd = ""
M.filenames = {}


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

            local augroup = "highlight_line_" .. win_id
            pcall(vim.api.nvim_del_augroup_by_name, augroup)
            pcall(vim.api.nvim_win_close, win_id, true)
        end
    )
end


--- Creates autocommand to highlight current line
---
--- @param win_id integer ID of floating window
--- @param buf_id integer ID of floating buffer
--- @param ns_id integer ID of highlight namespace
--- @param width integer width of window
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
            group = "highlight_line_" .. win_id,
            callback = function()
                local bufs = vim.api.nvim_list_bufs()
                local buf_open = false
                for _, buf in ipairs(bufs) do
                    if buf == buf_id then
                        buf_open = true
                        break
                    end
                end

                -- Cancel action if buffer has been closed
                if not buf_open then
                    return
                end
                local pos = vim.fn.getpos(".")
                if M.line_mark == nil then
                    M.line_mark = vim.api.nvim_buf_set_extmark(
                        buf_id, ns_id, M.line - 1, 0, {hl_group = "SignColumn", end_col = width - 1}
                    )
                else
                    M.line_mark = vim.api.nvim_buf_set_extmark(
                        buf_id, ns_id, M.line - 1, 0, {id = M.line_mark, hl_group = "SignColumn", end_col = width}
                    )
                end
                M.line = pos[2]
                M.line_mark = vim.api.nvim_buf_set_extmark(
                    buf_id, ns_id, M.line - 1, 0, {id = M.line_mark, hl_group = "TermCursor", end_col = width}
                )
            end
        }
    )
end


--- Configures floating window and sets up autocommand
---
--- @param win_id integer ID of floating window
--- @param buf_id integer ID of floating buffer
--- @param ns_id integer ID of highlight namespace
--- @param width integer width of window
--- @param previous_win integer ID of previous window
local function configure_floating_window(win_id, buf_id, ns_id, width, previous_win)
    -- Disable folding on current window
    vim.wo[win_id].foldenable = false

    vim.bo[buf_id].bufhidden = "wipe"

    for _, keymap in ipairs(config.opts.close_keymaps) do
        vim.keymap.set(
            "n",
            keymap,
            function()
                close_preview_window(win_id)
            end,
            { silent = true, noremap = true, nowait = true, buffer = true }
        )
    end

    highlight_line_autocmd(win_id, buf_id, ns_id, width)
    vim.api.nvim_buf_set_keymap(
        buf_id,
        "n",
        "<CR>",
        "",
        {
            callback = function()
                local pos = vim.fn.getpos(".")
                local line = pos[2]
                if M.filenames[line] == nil then
                    close_preview_window(win_id)
                else
                    local path = M.cwd .. "/" .. M.filenames[line]
                    close_preview_window(win_id)
                    vim.api.nvim_set_current_win(previous_win)
                    vim.cmd("edit " .. path)
                end
            end
        }
    )
end


--- Generate a selectable list of previous files
function M.where_was_i()
    M.cwd = vim.fn.getcwd()
    local file = 1

    local padding = string.rep(" ", config.opts.padding)
    local max_width = 1
    for f, _ in pairs(history.files) do
        if f:find(M.cwd) == 1 then
            local concat_filename = f:gsub(M.cwd .. "/", "")
            M.filenames[file] = concat_filename
            max_width = math.max(max_width, #M.filenames[file])
            file = file + 1
        end

        if file > config.opts.files then
            break
        end
    end

    local filenames_pad = {}
    local width = 1
    for k, v in pairs(M.filenames) do
        filenames_pad[k] = padding .. k .. " " .. string.format("%-" .. max_width .. "s", v) .. padding
        width = math.max(#filenames_pad[k], width)
    end
    width = math.max(width, 11)

    local viewport_width = vim.api.nvim_win_get_width(0)
    local viewport_height = vim.api.nvim_win_get_height(0)

    local height = math.max(file - 1, 1)

    local row = math.floor((viewport_height - height) / 2)
    local col = math.floor((viewport_width - width) / 2)

    local buf = vim.api.nvim_create_buf(false, true)
    if #filenames_pad == 0 then
        vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "   EMPTY   " })
    else
        vim.api.nvim_buf_set_lines(buf, 0, #filenames_pad, false, filenames_pad)
    end
    local previous_win = vim.api.nvim_get_current_win()
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
    configure_floating_window(win, buf, ns_id, width, previous_win)
end

return M
