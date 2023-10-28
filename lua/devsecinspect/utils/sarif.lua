-- Sarif library for parsing and processing sarif files
--
-- Based on the work from pwntegeek/codeql.nvim
-- https://github.com/pwntester/codeql.nvim/blob/master/lua/codeql/sarif.lua

local utils = require("devsecinspect.utils")
local config = require("devsecinspect.config").config
local ui = require("devsecinspect.ui")

local M = {}

--- Load a SARIF file from disk and parse it into a table
---@param filepath string
---@param opts table
---@return table | nil
function M.load(filepath, opts)
    opts = opts or {}
    if utils.is_file(filepath) == false then
        return nil
    end

    local data = utils.read_file(filepath)

    local ok, result = pcall(vim.fn.json_decode, data)
    if not ok then
        return nil
    end

    return result
end

--- Parse and process a SARIF table into a table of alerts
---@param filepath string
---@param opts table
---@return table | nil
function M.process(filepath, opts)
    opts = opts or {}
    -- sarif file data
    local sarif = M.load(filepath, opts)

    if sarif == nil and type(sarif) == "table" then
        utils.warning("Failed to parse sarif file")
        return nil
    end

    local results = {}

    utils.debug("Processing sarif file: " .. filepath)

    -- TODO(geekmasher): multiple runs
    local sarif_results = sarif.runs[1].results
    utils.debug("Found " .. #sarif_results .. " results")

    for i, result in ipairs(sarif_results) do
        local message = result.message.text
        local rule = result.ruleId
        local severity = result.level

        utils.debug("Processing alert: " .. rule)

        if result.codeFlows == nil then
            local location = result.locations[1].physicalLocation
            local line = location.region.startLine
            local column = location.region.startColumn
            local path = location.artifactLocation.uri

            local alert = {
                name = rule,
                message = message,
                severity = severity,
                location = {
                    file = path,
                    -- sarif is 1-indexed, vim is 0-indexed
                    line = line - 1,
                    column = column,
                },
            }


            table.insert(results, alert)
        else
            -- TODO(geekmasher): data flow
            utils.error("Data flow not currently supported")
        end

        ui.refresh()
    end

    return results
end

return M
