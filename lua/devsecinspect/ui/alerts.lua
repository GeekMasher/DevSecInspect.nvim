local utils = require("devsecinspect.utils")
local alerts = require("devsecinspect.alerts")

-- https://github.com/MunifTanjim/nui.nvim
local Popup = require("nui.popup")
local autocmd = require("nui.utils.autocmd")
local event = autocmd.event


local AlertsUi = {}
-- Panel config
AlertsUi.config = {}
-- Panel object
AlertsUi.panel = nil
-- table of alerts to display
AlertsUi.alerts = {}


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
        local panel = Popup({
            enter = false,
            focusable = true,
            relative = "win",
            border = {
                style = "rounded",
                text = {
                    top = ' ' .. name .. ' ',
                }
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
                readonly = false
            },
            win_options = {
                winblend = 10,
            }
        })

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

--- Clear the panel
function AlertsUi.clear(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local ns = vim.api.nvim_create_namespace("devsecinspect_alerts")
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    vim.diagnostic.reset(ns, bufnr)

    if AlertsUi.panel and AlertsUi.panel.bufnr then
        vim.api.nvim_buf_set_lines(AlertsUi.panel.bufnr, 0, -1, true, {})
    end
end

function AlertsUi.on_resize()
    if AlertsUi.panel ~= nil then
        AlertsUi.panel:update_layout({
            size = {
                width = AlertsUi.config.panel.size.width,
                height = AlertsUi.config.panel.size.height,
            }
        })
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
            utils.table_extend(result, opts.header)
        end
        -- append data
        AlertsUi.data = utils.table_extend(result, data)

        if opts.footer then
            if type(opts.footer) == "string" then
                opts.footer = { opts.footer }
            elseif type(opts.footer) == "boolean" then
                opts.footer = { "" }
            end
            utils.table_extend(result, opts.footer)
        end

        vim.api.nvim_buf_set_lines(AlertsUi.panel.bufnr, 0, -1, true, result)
    end
end

--- Render the alerts
---@param bufnr integer | nil
function AlertsUi.render(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    AlertsUi.clear(bufnr)

    -- tools
    local tools = require("devsecinspect.tools")
    AlertsUi.render_tools(tools.tools)

    -- TODO(geekmasher): what about results in other files / buffers?

    -- check to see if there are any alerts to display
    if next(alerts.results) == nil then
        -- close the panel if it's open
        if AlertsUi.config.panel.enabled == false and AlertsUi.config.panel.auto_close == true then
            AlertsUi.close()
        end
        utils.debug("ui.alerts.render: No alerts found")
        return
    end

    -- check to see if the panel should be open
    if AlertsUi.config.panel ~= nil or AlertsUi.config.panel.enable == true then
        AlertsUi.open()
    end

    -- render in in-line diagnostics
    if AlertsUi.config.mode ~= nil and AlertsUi.config.mode == "summarised" then
        AlertsUi.render_summarised(bufnr, alerts.results)
    elseif AlertsUi.config.mode ~= nil and AlertsUi.config.mode == "full" then
        AlertsUi.render_diagnostic(bufnr, alerts.results)
    else
        utils.error("ui.alerts.render: Invalid mode")
    end

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
            " > " .. category
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
        local status = tool.running and AlertsUi.config.symbols.enabled or AlertsUi.config.symbols.disabled

        if tool.status == true then
            local msg = " -> " .. status .. " " .. tool.name .. " (" .. tool.type .. ")"

            if tool.message then
                msg = msg .. " [" .. tool.message .. "]"
            end

            available_tools[#available_tools + 1] = msg
        end
    end


    -- add empty line
    AlertsUi.append_data(available_tools, {
        header = { "Tools", "" },
        footer = true
    })
end

--- Display the summarised information for all alerts
---@param bufnr integer
---@param alerts table
function AlertsUi.render_summarised(bufnr, alerts)
end

--- Display the diagnostic information for an alert
---@param bufnr integer
---@param alerts table
function AlertsUi.render_diagnostic(bufnr, alerts)
    AlertsUi.clear(bufnr)

    for _, instances in pairs(alerts) do
        for _, alert in pairs(instances) do
            if AlertsUi.filter_alert(alert) then
                AlertsUi.show_diagnostic(bufnr, alert)
            end
        end
    end
end

function AlertsUi.show_diagnostic(bufnr, alert)
    local ns = vim.api.nvim_create_namespace("devsecinspect_alerts")

    local location = alert.location or {}
    local text = AlertsUi.find_severity_symbol(alert.severity) .. " " .. alert.name

    local existing = vim.api.nvim_buf_get_extmarks(
        bufnr, ns, { location.line, 0 }, { location.line, -1 }, {}
    )

    if existing and #existing > 0 then
        return
    end

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

return AlertsUi
