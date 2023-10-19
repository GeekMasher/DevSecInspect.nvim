local M = {}

--- Merge a table with another table
---@param t1 table
---@param t2 table
---@return table
function M.table_merge(t1, t2)
    if t1 and t2 then
        for k, v in pairs(t2) do
            if type(v) == "table" then
                if type(t1[k] or false) == "table" then
                    M.table_merge(t1[k] or {}, t2[k] or {})
                else
                    t1[k] = v
                end
            else
                t1[k] = v
            end
        end
        return t1
    end
end

--- Extend a table with another table
---@param t1 table
---@param t2 table
---@return table
function M.table_extend(t1, t2)
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

--- Filter paths
---@param filepath string
---@param filters table
---@return boolean
function M.match_globs(filepath, filters)
    -- if filters is empty, return true
    if not filters then
        return true
    end

    for _, filter in ipairs(filters) do
        if string.match(filepath, filter) then
            return true
        end
    end
    return false
end

function M.match_language(bufrn, languages)
    local filetype = vim.api.nvim_buf_get_option(bufrn, "filetype")
    print("FILETYPE :: " .. filetype)

    if not filetype then
        return false
    end

    for _, language in ipairs(languages) do
        if filetype == language then
            return true
        end
    end
    return false
end

--- Join table to path
---@param ... table
---@return string
function M.join_path(...)
    local args = { ... }
    if #args == 0 then
        return ""
    end

    return table.concat(args, "/")
end

--- Check if the filepath provided is a file
---@param filepath string
---@return boolean
function M.is_file(filepath)
    local stat = vim.loop.fs_stat(filepath)
    return stat and stat.type == "file" or false
end

--- Check if the filepath provided is a directory
---@param filepath string
---@return boolean
function M.is_dir(filepath)
    local stat = vim.loop.fs_stat(filepath)
    return stat and stat.type == "directory" or false
end

--- Read a file from disk
---@param filepath string
---@return string
function M.read_file(filepath)
    local f = io.open(filepath, "r")
    if not f then
        return nil
    end
    local content = f:read("*all")
    f:close()
    return content
end

return M
