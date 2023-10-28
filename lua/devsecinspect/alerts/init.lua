local config = require("devsecinspect.config")

local M = {}
M.bufnr = nil
M.filepath = nil

-- Table of all the results from the tools
M.results = {}

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
        vim.api.nvim_err_writeln("Tool and alert is required")
        return
    end

    if not alert.name or not alert.location then
        vim.api.nvim_err_writeln("Alert missing required fields")
        return
    end

    if not M.results[tool] then
        M.results[tool] = {}
    end
    -- TODO(geekmasher): does column matter?
    local alertkey = alert.name .. "#" .. alert.location.line
    if not M.results[tool][alertkey] then
        M.results[tool][alertkey] = alert
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

function M.show_diagnostic(bufnr, alert)
    local ns = vim.api.nvim_create_namespace(config.name)

    local location = alert.location or {}
    local text = config.config.symbols.error .. " " .. alert.name

    vim.api.nvim_buf_set_extmark(
        bufnr, ns, location.line, 0,
        {
            hl_mode = "replace",
            hl_group = "Alert",
            virt_text_pos = "eol",
            virt_text = { { text } }
        }
    )
end

--- Reset the alerts table
function M.reset(bufnr, ns)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    ns = ns or vim.api.nvim_create_namespace(config.name)
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    vim.diagnostic.reset(ns, bufnr)

    M.results = {}
end

return M
