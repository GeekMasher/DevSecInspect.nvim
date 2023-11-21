local PackageJson = {}


--- Find locations of dependencies in the buffer
---@param bufnr integer
---@param filepath string
---@return table
function PackageJson:locations(bufnr, filepath)
    -- find location of dependencies in the buffer
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local in_deps = false

    local results = {}

    for line_number, content in ipairs(lines) do
        if string.match(content, "[\"|\']dependencies[\"|\']:") then
            in_deps = true
        elseif in_deps == true and string.match(content, "^.*},?") then
            in_deps = false
        elseif in_deps == true then
            local dep = string.match(content, "[\"|\'](.*)[\"|\']:")
            local first_quote = string.find(content, "[\"|\']") or 0

            results[dep] = {
                line = line_number - 1,
                column = first_quote,
                column_end = #content,
                file = filepath,
                filename = vim.fn.fnamemodify(filepath, ":t")
            }
        end
    end

    return results
end

return PackageJson
