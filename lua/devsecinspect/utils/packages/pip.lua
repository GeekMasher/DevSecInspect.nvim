local Pip = {}

--- Find locations of dependencies in the buffer
---@param bufnr integer
---@param filepath string
---@return table
function Pip:locations(bufnr, filepath)
    if filepath:match "requirements.txt" then
        return self:requirements(bufnr, filepath)
    else
        return {}
    end
end

function Pip:requirements(bufnr, filepath)
    -- find location of dependencies in the buffer
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local results = {}

    for line_number, content in ipairs(lines) do
        local dep = string.match(content, "^[a-zA-Z0-9-_]+")

        results[dep] = {
            line = line_number - 1,
            column_end = #content,
            file = filepath,
            filename = vim.fn.fnamemodify(filepath, ":t"),
        }
    end

    return results
end

return Pip
