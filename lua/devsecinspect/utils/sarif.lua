-- Sarif library for parsing and processing sarif files
--
-- Based on the work from pwntegeek/codeql.nvim
-- https://github.com/pwntester/codeql.nvim/blob/master/lua/codeql/sarif.lua

local Alert = require "devsecinspect.alerts.alert"
local utils = require "devsecinspect.utils"
local config = require("devsecinspect.config").config
local ui = require "devsecinspect.ui"

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

    if sarif == nil or type(sarif) ~= "table" then
        utils.warning "Failed to parse sarif file"
        return nil
    end

    local tool = opts.tool or "devsecinspect"
    local results = {}

    utils.debug("Processing sarif file: " .. filepath)

    -- TODO(geekmasher): multiple runs
    local sarif_results = sarif.runs[1].results

    local rules = sarif.runs[1].tool.driver.rules

    utils.debug("Found " .. #sarif_results .. " results")

    for i, result in ipairs(sarif_results) do
        local message = result.message.text
        local rule_id = result.ruleId

        utils.debug("Processing alert: " .. rule_id)

        if result.codeFlows == nil then
            local location = result.locations[1].physicalLocation
            local line = location.region.startLine
            local column = location.region.startColumn
            local path = location.artifactLocation.uri

            local rule = M.lookup_rule(rules, rule_id)

            local alert_location = {
                file = path,
                line = line - 1,
                column = column,
            }

            local alert = Alert:new(tool, rule_id, alert_location, {
                severity = M.find_severity(rule),
                message = message,
                references = {
                    rule.helpUri,
                },
            })

            table.insert(results, alert)
        else
            -- TODO(geekmasher): data flow
            utils.error "Data flow not currently supported"
        end

        ui.refresh()
    end

    return results
end

function M.lookup_rule(rules, rule_id)
    for _, rule in ipairs(rules) do
        if rule.id == rule_id then
            return rule
        end
    end
    return {}
end

--- Find the severity of a rule
---@param rule table
---@return string
function M.find_severity(rule)
    if not rule.defaultConfiguration then
        return "info"
    end

    local severity = rule.defaultConfiguration.severity
    if severity == "error" then
        return "high"
    elseif severity == "warning" then
        return "medium"
    elseif severity == "note" then
        return "info"
    else
        return "info"
    end
end

return M
