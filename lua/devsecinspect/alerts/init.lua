local config = require("devsecinspect.config")
local utils = require("devsecinspect.utils")
local Alert = require("devsecinspect.alerts.alert")

local M = {}
M.bufnr = nil
M.filepath = nil

-- Table of all the results from the tools
-- category {
--    instance {
--        alert
--    }
-- }
M.results = {}
-- Table of all the unique keys for the results.
M.result_summaries = {}



function M.check_results(tool)
    if not M.results[tool] then
        return false
    end
    return true
end

--- Add Alerts to the alerts table
---@param alert table
function M.add_alert(tool, alert)
    M.append(tool, alert)
end

--- Add an alert to the alerts table
---@param tool string
---@param alert table
function M.append(tool, alert)
    if tool == nil or alert == nil then
        utils.error("Tool and alert is required")
        return
    end

    if not alert.name then
        utils.error("Alert missing required `name` field")
        return
    end

    local alt = Alert:new(tool, alert.name, alert.location, {
        message = alert.message,
        category = alert.name,
        severity = alert.severity,
        cwes = alert.cwes,
        paths = alert.paths,
    })

    -- build table tree
    if not M.results[alt.category] then
        M.results[alt.category] = {}
    end

    -- instance
    local instance = alert.name .. "#" .. alert.location.line
    if not M.results[alt.category][instance] then
        utils.debug("Adding alert to results table")
        M.results[alt.category][instance] = alert
    else
        utils.debug("Alert already exists in this instance")
    end
end

--- Extend the alerts table
---@param tool string
---@param results table
function M.extend(tool, results)
    for _, result in ipairs(results) do
        M.append(tool, result)
    end
end

--- Reset the alerts table
function M.reset(bufnr, ns)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    ns = ns or vim.api.nvim_create_namespace(config.name)
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    vim.diagnostic.reset(ns, bufnr)
end

--- Clear the alerts table
function M.clear(bufnr)
    M.results = {}
end

return M
