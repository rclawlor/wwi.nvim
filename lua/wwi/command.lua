local M = {}


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


--- Creates autocommand to close floating window based on events
---
--- @param events table list of events
--- @param win_id integer ID of floating window
--- @param buf_ids table IDs of buffers where floating window can be seen
local function close_win_autocmd(events, win_id, buf_ids)
    local augroup = vim.api.nvim_create_augroup("floating_window_" .. win_id, {
        clear = true,
    })
    -- close the preview window when entered a buffer that is not
    -- the floating window buffer or the buffer that spawned it
    vim.api.nvim_create_autocmd("BufEnter", {
        group = augroup,
        callback = function()
            close_preview_window(win_id, buf_ids)
        end,
    })

    if #events > 0 then
        vim.api.nvim_create_autocmd(events, {
            group = augroup,
            callback = function()
                close_preview_window(win_id)
            end,
        })
    end
end


--- Configures floating window and sets up autocommand
---
--- @param win_id integer ID of floating window
--- @param buf_id integer ID of floating buffer
local function configure_floating_window(win_id, buf_id)
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

    -- local close_events = { 'CursorMoved' }
    -- close_win_autocmd(close_events, win_id, { buf_id })
end

--- Generate a list
function M.where_was_i()
    local cwd = vim.fn.getcwd()
    local files = vim.v.oldfiles
    local filenames = {}
    for idx = 1, 10, 1 do
        local filename = files[idx]
        if filename:find(cwd) == 1 then
            filenames[idx] = filename:gsub(cwd .. "/", "")
        end
    end

    local viewport_width = vim.api.nvim_win_get_width(0)
    local viewport_height = vim.api.nvim_win_get_height(0)

    local scale = 0.5
    local width = math.floor(viewport_width * scale)
    local height = math.floor(viewport_height * scale)

    local row = math.floor((viewport_height - height) / 2)
    local col = math.floor((viewport_width - width) / 2)

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 1, -1, true, {"Hello, World!"})
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
    vim.api.nvim_buf_set_extmark(buf, ns_id, 1, 1, {hl_group = "Cursor", end_col = 10})
    configure_floating_window(win, buf)
end

return M
