local alerts = require "devsecinspect.alerts"
local utils = require "devsecinspect.utils"

-- https://github.com/MunifTanjim/nui.nvim
local Popup = require "nui.popup"
local autocmd = require "nui.utils.autocmd"
local event = autocmd.event

local AlertsUi = {}
-- Panel config
AlertsUi.config = {}
-- Panel object
AlertsUi.panel = nil
-- table of alerts to display
AlertsUi.alerts = {}
-- diagnostics
AlertsUi.diagnostics = {}

function AlertsUi.setup(opts)
    AlertsUi.config.symbols = opts.symbols
    utils.table_merge(AlertsUi.config, opts.alerts or {})

    -- Setup Panel
    AlertsUi.create("DevSecInspect Alerts", {}, { persistent = true })
    if AlertsUi.config.panel.enabled == true then
        AlertsUi.open()
    end
end

--- Create the panel
---@param name string
---@param data table | nil
---@param opts table | nil
function AlertsUi.create(name, data, opts)
    data = data or {}
    opts = opts or {}

    local bufnr = vim.api.nvim_get_current_buf()

    if AlertsUi.panel == nil then
        local panel = Popup {
            enter = false,
            focusable = true,
            relative = "win",
            border = {
                style = "rounded",
                text = {
                    top = " " .. name .. " ",
                },
            },
            position = {
                row = AlertsUi.config.panel.position.row or "",
                col = AlertsUi.config.panel.position.col,
            },
            size = {
                width = AlertsUi.config.panel.size.width,
                height = AlertsUi.config.panel.size.height,
            },
            buf_options = {
                modifiable = true,
                readonly = false,
            },
            win_options = {
                winblend = 10,
            },
        }

        if not opts.persistent then
            autocmd.buf.define(bufnr, event.CursorMoved, function()
                panel:unmount()
                AlertsUi.panel = nil
            end, { once = true })
        end

        AlertsUi.panel = panel
    end
end

--- Open the panel
function AlertsUi.open()
    if AlertsUi.panel then
        AlertsUi.panel:mount()
    end
end

--- Close the panel
function AlertsUi.close()
    if AlertsUi.panel then
        AlertsUi.panel:unmount()
    end
end

function AlertsUi.toggle()
    if AlertsUi.panel then
        if AlertsUi.panel.mounted == true then
            AlertsUi.close()
        else
            AlertsUi.open()
        end
    end
end

--- Clear the panel
function AlertsUi.clear(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    AlertsUi.clear_diagnostics(bufnr)

    if AlertsUi.panel and AlertsUi.panel.bufnr then
        vim.api.nvim_buf_set_lines(AlertsUi.panel.bufnr, 0, -1, true, {})
    end
end

--- Clear the diagnostics
---@param bufnr integer
function AlertsUi.clear_diagnostics(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local ns = vim.api.nvim_create_namespace "devsecinspect_alerts"
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    vim.diagnostic.reset(ns, bufnr)
    AlertsUi.diagnostics = {}
end

function AlertsUi.on_resize()
    if AlertsUi.panel ~= nil and AlertsUi.panel.mounted ~= nil then
        AlertsUi.panel:update_layout {
            size = {
                width = AlertsUi.config.panel.size.width,
                height = AlertsUi.config.panel.size.height,
            },
        }
    end
end

--- Refresh the alerts panel
---@param bufnr integer
---@param filepath string
function AlertsUi.refresh(bufnr, filepath)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    filepath = filepath or vim.api.nvim_buf_get_name(bufnr)

    AlertsUi.clear(bufnr)

    AlertsUi.render(bufnr)
end

--- Set the data for the panel
---@param data table
function AlertsUi.set_data(data)
    if AlertsUi.panel and data ~= nil then
        -- overwrite data and set it
        vim.api.nvim_buf_set_lines(AlertsUi.panel.bufnr, 0, -1, true, data)
    end
end

--- Append data to the panel
---@param data table
function AlertsUi.append_data(data, opts)
    opts = opts or {}
    -- get previous data from panel
    local result = vim.api.nvim_buf_get_lines(AlertsUi.panel.bufnr, 0, -1, true)

    if AlertsUi.panel and data ~= nil then
        if opts.header then
            if type(opts.header) == "string" then
                opts.header = { opts.footer }
            elseif type(opts.header) == "boolean" then
                opts.header = { "" }
            end
            result = utils.table_extend(result, opts.header)
        end
        -- append data
        result = utils.table_extend(result, data)

        if opts.footer then
            if type(opts.footer) == "string" then
                opts.footer = { opts.footer }
            elseif type(opts.footer) == "boolean" then
                opts.footer = { "" }
            end
            result = utils.table_extend(result, opts.footer)
        end

        vim.api.nvim_buf_set_lines(AlertsUi.panel.bufnr, 0, -1, true, result)
    end
end

--- Render the alerts
---@param bufnr integer | nil
function AlertsUi.render(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local ns = vim.api.nvim_create_namespace "devsecinspect_alerts"

    AlertsUi.clear(bufnr)

    -- tools
    local tools = require "devsecinspect.tools"
    AlertsUi.render_tools(tools.tools)

    -- TODO(geekmasher): what about results in other files / buffers?

    -- check to see if there are any alerts to display
    if next(alerts.results) == nil then
        -- close the panel if it's open
        if AlertsUi.config.panel.enabled == false and AlertsUi.config.panel.auto_close == true then
            AlertsUi.close()
        end
        utils.debug "ui.alerts.render: No alerts found"
        return
    end

    -- check to see if the panel should be open
    if AlertsUi.config.panel ~= nil or AlertsUi.config.panel.enable == true then
        AlertsUi.open()
    end

    -- Render in in-line diagnostics
    -- Summary
    AlertsUi.render_summarised(bufnr, alerts.results)
    -- or; full diagnostic
    AlertsUi.render_diagnostic(bufnr, alerts.results)

    -- Set all Diagnostics
    vim.diagnostic.set(ns, bufnr, AlertsUi.diagnostics)

    -- alerts
    if AlertsUi.panel ~= nil and AlertsUi.config.panel.enabled == true then
        AlertsUi.render_alert_tree(bufnr, alerts.results)
    end
end

--- Render the alerts in panel
---@param bufnr integer
---@param alerts table
function AlertsUi.render_alert_tree(bufnr, alerts)
    -- alerts
    AlertsUi.append_data({ "Alerts", "" }, { header = true })

    for category, instances in pairs(alerts) do
        local display_alerts = {
            " > " .. category,
        }

        for instance, alert in pairs(instances) do
            local severity = AlertsUi.find_severity_symbol(alert.severity)

            if AlertsUi.filter_alert(alert) then
                local line = "   - " .. severity .. " " .. instance

                display_alerts[#display_alerts + 1] = line
            end
        end

        AlertsUi.append_data(display_alerts)
    end
end

--- Find the symbol for the severity
---@param severity string
---@return string
function AlertsUi.find_severity_symbol(severity)
    severity = severity or ""

    if severity == "critical" or severity == "high" or severity == "very-high" then
        return AlertsUi.config.symbols.error
    end
    if severity == "medium" or severity == "moderate" then
        return AlertsUi.config.symbols.warning
    end
    if severity == "low" or severity == "very-low" or severity == "info" then
        return AlertsUi.config.symbols.info
    end
    return AlertsUi.config.symbols.debug
end

AlertsUi.severities = {
    critical = 1,
    high = 2,
    medium = 3,
    low = 4,
    info = 5,
    debug = 6,
}

function AlertsUi.filter_alert(alert)
    -- TODO(geekmasher): filters
    return true
end

--- Render the tools
function AlertsUi.render_tools(tools)
    -- sort tools by name
    table.sort(tools, function(a, b)
        return a.name < b.name
    end)

    local available_tools = {}

    for _, tool in pairs(tools) do
        local status = tool.status and AlertsUi.config.symbols.enabled or AlertsUi.config.symbols.disabled

        if tool.status == true then
            local msg = " -> " .. status .. " " .. tool.name .. " (" .. tool.type .. ")"

            if tool.message then
                msg = msg .. " [" .. tool.message .. "]"
            end

            available_tools[#available_tools + 1] = msg
        end
    end

    AlertsUi.append_data(available_tools, {
        header = { "Tools", "" },
        footer = true,
    })
end

--- Display the summarised information for all alerts
---@param bufnr integer
---@param alerts table
function AlertsUi.render_summarised(bufnr, alerts)
    AlertsUi.clear_diagnostics(bufnr)

    local ns = vim.api.nvim_create_namespace "devsecinspect_alerts"

    local total_summary = {
        critical = 0,
        high = 0,
        medium = 0,
        low = 0,
        info = 0,
        debug = 0,
    }

    -- { [number] = { high = 0 } }
    local line_summaries = {}

    for _, instances in pairs(alerts) do
        for _, alert in pairs(instances) do
            if AlertsUi.filter_alert(alert) then
                -- add one to the total summary
                total_summary[alert.severity] = total_summary[alert.severity] + 1

                -- TODO(geekmasher)
                if line_summaries[alert.location.line] == nil then
                    line_summaries[alert.location.line] = {
                        critical = 0,
                        high = 0,
                        medium = 0,
                        low = 0,
                        info = 0,
                        debug = 0,
                    }
                end

                line_summaries[alert.location.line][alert.severity] = line_summaries[alert.location.line]
                    [alert.severity]
                    + 1
            end
        end
    end

    if AlertsUi.config.mode ~= nil and AlertsUi.config.mode == "summarised" then
        AlertsUi.show_summary_diagnostics(bufnr, line_summaries)
    end

    local render_summary = {
        "Alert Summary",
        "",
        " > Critical: " .. total_summary.critical,
        " > High: " .. total_summary.high,
        " > Medium: " .. total_summary.medium,
        " > Low: " .. total_summary.low,
        " > Info: " .. total_summary.info,
        " > Debug: " .. total_summary.debug,
    }

    AlertsUi.append_data(render_summary, { header = true })
end

--- Display the diagnostic information for an alert
---@param bufnr integer
---@param alerts table
function AlertsUi.render_diagnostic(bufnr, alerts)
    AlertsUi.clear_diagnostics(bufnr)

    for _, instances in pairs(alerts) do
        for _, alert in pairs(instances) do
            if AlertsUi.filter_alert(alert) then
                if AlertsUi.config.mode ~= nil and AlertsUi.config.mode == "full" then
                    AlertsUi.show_alert_diagnostic(bufnr, alert)
                end

                local severity = alert:get_severity_level()

                -- https://neovim.io/doc/user/diagnostic.html#vim.diagnostic.set()
                AlertsUi.diagnostics[#AlertsUi.diagnostics + 1] = {
                    bufnr = bufnr,
                    lnum = alert.location.line,
                    col = alert.location.column or 0,
                    end_col = alert.location.column_end or 0,
                    severity = severity,
                    message = alert.name,
                }
            end
        end
    end
end

--- Display inline diagnostic information for an alert
---@param bufnr integer
---@param alert table
function AlertsUi.show_alert_diagnostic(bufnr, alert)
    local ns = vim.api.nvim_create_namespace "devsecinspect_alerts"

    local location = alert.location or {}
    local text = AlertsUi.find_severity_symbol(alert.severity) .. " " .. alert.name

    -- TODO(geekmasher): do we need to check for existing marks?
    -- local existing = vim.api.nvim_buf_get_extmarks(
    --     bufnr, ns, { location.line, 0 }, { location.line, -1 }, {}
    -- )
    -- if existing and #existing > 0 then
    --     return
    -- end

    -- check to see if the full mode is enabled
    vim.api.nvim_buf_set_extmark(bufnr, ns, location.line, 0, {
        hl_mode = "replace",
        hl_group = "Alert",
        virt_text_pos = "eol",
        virt_text = { { text } },
    })
end

--- Show the summary diagnostic information
---@param bufnr integer
---@param summaries table
function AlertsUi.show_summary_diagnostics(bufnr, summaries)
    for line, summary in pairs(summaries) do
        AlertsUi.show_summary_diagnostic(bufnr, line, summary)
    end
end

--- Show a Summary of the diagnostic information
---@param bufnr integer
---@param line integer
---@param summary table
function AlertsUi.show_summary_diagnostic(bufnr, line, summary)
    local ns = vim.api.nvim_create_namespace "devsecinspect_alerts"

    for severity, count in pairs(summary) do
        if count ~= 0 then
            local severity_symbol = AlertsUi.find_severity_symbol(severity)

            local text = severity_symbol .. " " .. count .. " " .. severity .. " alerts"
            vim.api.nvim_buf_set_extmark(bufnr, ns, line, 0, {
                hl_mode = "replace",
                hl_group = "Alert",
                virt_text_pos = AlertsUi.config.text_position,
                virt_text = { { text } },
            })
        end
    end
end

return AlertsUi
