local M = {}

--- Debugging function
---@param msg string
---@param opts table | nil
function M.debug(msg, opts)
    local config = require("devsecinspect.config").config
    local panel = require("devsecinspect.ui.panel")

    opts = opts or {}
    panel.messages[#panel.messages + 1] = "[" .. config.symbols.debug .. "] " .. msg
end

--- Info function
---@param msg string
---@param opts table | nil
function M.info(msg, opts)
    local config = require("devsecinspect.config").config
    local panel = require("devsecinspect.ui.panel")

    opts = opts or {}
    panel.messages[#panel.messages + 1] = "[" .. config.symbols.info .. "] " .. msg
    if opts.show then
        vim.api.nvim_out_write(msg .. "\n")
    end
end

function M.warning(msg, opts)
    local config = require("devsecinspect.config").config
    local panel = require("devsecinspect.ui.panel")

    opts = opts or {}
    panel.messages[#panel.messages + 1] = "[" .. config.symbols.warning .. "] " .. msg
    vim.api.nvim_err_writeln(msg)
end

function M.error(msg, opts)
    local config = require("devsecinspect.config").config
    local panel = require("devsecinspect.ui.panel")

    opts = opts or {}
    panel.messages[#panel.messages + 1] = "[" .. config.symbols.error .. "] " .. msg
    vim.api.nvim_err_writeln(msg)
end

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

--- Check if the current buffer is a supported language
---@param bufrn any
---@param languages any
---@return boolean
function M.match_language(bufrn, languages)
    languages = languages or {}
    local filetype = vim.api.nvim_buf_get_option(bufrn, "filetype")

    if not filetype then
        return false
    elseif #languages == 0 then
        print("Languages is empty... this shouldn't happen")
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

--- Split a string
---@param str any
---@return table
function M.split(str, char)
    local t = {}
    for w in string.gmatch(str, "([^" .. char .. "]+)") do
        table.insert(t, w)
    end
    return t
end

--- Contains a string in a table of strings
---@param str string
---@param data table
---@return boolean
function M.contains(str, data)
    if type(data) == "table" then
        for _, v in ipairs(data) do
            if string.find(str, v) then
                return true
            end
        end
    end
    return false
end

--- Create a markdown table
---@param header table
---@param data table
---@return table
function M.create_markdown_table(header, data)
    local lines = {}
    -- header
    table.insert(lines, "| " .. table.concat(header, " | ") .. " |")

    -- table content
    for _, v in pairs(data) do
        table.insert(lines, "| " .. table.concat(v, " | ") .. " |")
    end

    return lines
end

return M
