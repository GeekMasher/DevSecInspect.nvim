local config = require("devsecinspect.config")

local M = {}
M.bufnr = nil
M.filepath = nil

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
    -- check required fields
    if not alert.name then
        vim.api.nvim_err_writeln("Alert missing required fields")
        return
    end
    -- set default location
    if not alert.location then
        local filepath = vim.fn.expand("%:p")
        alert.location = { file = filepath, line = 0 }
    end

    if not M.results[tool] then
        M.results[tool] = {}
    end

    if not M.results[tool][alert.name] then
        M.results[tool][alert.name] = alert
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
