local M = {}

--- Generate a list
function M.where_was_i()
    local cwd = vim.fn.getcwd()
    local files = vim.v.oldfiles
    for idx = 1, 10, 1 do
        local filename = files[idx]
        if filename:find(cwd) == 1 then
            print(filename:gsub(cwd, ""))
        end
    end
end

return M
