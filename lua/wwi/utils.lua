local M = {}

--- Check if path is a file
---
--- @param path string file path
function M.file_exists(path)
    local f = io.open(path, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end


return M
