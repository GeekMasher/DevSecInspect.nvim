local utils = require("devsecinspect.utils")
local config = require("devsecinspect.config")

-- https://github.com/MunifTanjim/nui.nvim
local Popup = require("nui.popup")
local autocmd = require("nui.utils.autocmd")
local event = autocmd.event


local M = {}
M.panel = nil
-- name of the file being inspected
M.filepath = nil
-- list of available tools
M.tools = {}
-- list of alerts
M.alerts = {}

--- Create the panel
---@param name string
---@param data table optional
---@param opts table optional
function M.create_panel(name, data, opts)
    data = data or {}
    opts = opts or {}

    local bufnr = vim.api.nvim_get_current_buf()

    if M.panel == nil then
        local panel = Popup({
            enter = false,
            focusable = false,
            relative = "win",
            border = {
                style = "rounded",
                text = {
                    top = ' ' .. name .. ' '
                }
            },
            position = {
                row = "0%",
                col = "100%"
            },
            size = {
                width = "30%",
                height = "97%",
            },
            buf_options = {
                modifiable = true,
                readonly = false
            },
            win_options = {
                winblend = 10,
            }
        })

        if not opts.persistent then
            autocmd.buf.define(bufnr, event.CursorMoved, function()
                panel:unmount()
                M.panel = nil
            end, { once = true })
        end

        M.panel = panel
    end

    M.set_data(data)
end

--- Open the panel
function M.open()
    if M.panel then
        M.panel:mount()
    end
end

--- Close the panel
function M.close()
    if M.panel then
        M.panel:unmount()
    end
end

--- Clear the panel
function M.clear()
    if M.panel and M.panel.bufnr then
        vim.api.nvim_buf_set_lines(M.panel.bufnr, 0, -1, true, {})
    end
end

--- Set the data for the panel
---@param data table
function M.set_data(data)
    if M.panel and data ~= nil then
        -- overwrite data and set it
        vim.api.nvim_buf_set_lines(M.panel.bufnr, 0, -1, true, data)
    end
end

--- Append data to the panel
---@param data table
function M.append_data(data, opts)
    opts = opts or {}
    local result = {}

    if M.panel and data ~= nil then
        if opts.header then
            if type(opts.header) == "string" then
                opts.header = { opts.footer }
            elseif type(opts.header) == "boolean" then
                opts.header = { "" }
            end
            utils.table_extend(result, opts.header)
        end
        -- append data
        M.data = utils.table_extend(result, data)

        if opts.footer then
            if type(opts.footer) == "string" then
                opts.footer = { opts.footer }
            elseif type(opts.footer) == "boolean" then
                opts.footer = { "" }
            end
            utils.table_extend(result, opts.footer)
        end

        vim.api.nvim_buf_set_lines(M.panel.bufnr, 0, -1, true, result)
    end
end

--- Append a tool to the panel
---@param name string
---@param status boolean
function M.append_tool(name, status)
    if type(name) ~= "string" then
        return
    end
    M.tools[#M.tools + 1] = " -> " .. (status and "✅ " or "❌ ") .. name
end

function M.render(filepath)
    filepath = filepath or vim.fn.expand("%:p")

    M.clear()

    M.render_tools()
    M.render_alerts()
end

--- Render the alerts
function M.render_alerts()
    local alerts = require("devsecinspect.alerts")
    local data = {}

    for alert_tool, alert in pairs(alerts.results) do
        data[#data + 1] = " > " .. alert_tool

        for _, alrt in pairs(alert) do
            data[#data + 1] = "   - " .. alrt.name
            alerts.show_diagnostic(alerts.bufnr, alrt)
        end

        M.append_data(data, {
            header = { "Alerts - " .. alert_tool, "" },
            footer = true
        })
    end
end

function M.render_tools()
    local available_tools = {}

    for _, tool in pairs(M.tools) do
        available_tools[#available_tools + 1] = tool
    end
    -- add empty line
    M.append_data(available_tools, {
        header = { "Available Tools", "" },
        footer = true
    })
end

return M
