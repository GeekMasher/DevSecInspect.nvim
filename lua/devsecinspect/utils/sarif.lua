local utils = require("devsecinspect.utils")

local M = {}

--- Load a SARIF file from disk and parse it into a table
---@param filepath string
---@param opts table
---@return table | nil
function M.loadSarif(filepath, opts)
    opts = opts or {}

    local data = utils.read_file(filepath)

    local ok, result = pcall(vim.fn.json_decode, data)
    if not ok then
        return nil
    end

    return M.parseSarif(result, opts)
end

--- Parse a SARIF table into a table of alerts
---@param data table
---@param opts table
---@return table
function M.parseSarif(data, opts)
    opts = opts or {}

    local alerts = {}
    return alerts
end

return M
