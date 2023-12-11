local utils = require("devsecinspect.utils")

-- https://github.com/MunifTanjim/nui.nvim
local Popup = require("nui.popup")
local autocmd = require("nui.utils.autocmd")
local event = autocmd.event


local Debugging = {}
-- Debugging config
Debugging.config = {}
-- Panel
Debugging.panel = nil
-- name of the file being inspected
Debugging.filepath = nil
-- list of available tools
Debugging.tools = {}
-- list of alerts
Debugging.alerts = {}

-- list of messages
Debugging.messages = {}


function Debugging.setup(opts)
    Debugging.config.symbols = opts.symbols
    utils.table_merge(Debugging.config, opts.debugging or {})

    -- Setup Panel
    Debugging.create("DevSecInspect Alerts", {}, { persistent = true })
    if opts.enabled == true then
        Debugging.open()
    end
end

--- Create the panel
---@param name string
---@param data table optional
---@param opts table optional
function Debugging.create(name, data, opts)
    data = data or {}
    opts = opts or {}

    local bufnr = vim.api.nvim_get_current_buf()

    if Debugging.panel == nil then
        local panel = Popup({
            enter = false,
            focusable = false,
            relative = "win",
            border = {
                style = "rounded",
                text = {
                    top = ' DevSecInspect Debugging '
                }
            },
            position = {
                row = Debugging.config.panel.position.row or "79%",
                col = Debugging.config.panel.position.col or "0%",
            },
            size = {
                width = Debugging.config.panel.size.width or "70%",
                height = Debugging.config.panel.size.height or "20%",
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
                Debugging.panel = nil
            end, { once = true })
        end

        Debugging.panel = panel
    end

    Debugging.set_data(data)
end

--- Open the panel
function Debugging.open()
    if Debugging.panel then
        Debugging.panel:mount()
    end
end

--- Close the panel
function Debugging.close()
    if Debugging.panel then
        Debugging.panel:unmount()
    end
end

--- Clear the panel
function Debugging.clear()
    if Debugging.panel and Debugging.panel.bufnr then
        vim.api.nvim_buf_set_lines(Debugging.panel.bufnr, 0, -1, true, {})
    end
end

function Debugging.on_resize()
    if Debugging.panel ~= nil then
        local config = require("devsecinspect.config").config
        Debugging.panel:update_layout({
            size = {
                width = config.debugging.panel.size.width,
                height = config.debugging.panel.size.height,
            }
        })
    end
end

--- Set the data for the panel
---@param data table
function Debugging.set_data(data)
    if Debugging.panel and data ~= nil then
        -- overwrite data and set it
        vim.api.nvim_buf_set_lines(Debugging.panel.bufnr, 0, -1, true, data)
    end
end

--- Append data to the panel
---@param data table
function Debugging.append_data(data, opts)
    opts = opts or {}
    -- get previous data from panel
    local result = vim.api.nvim_buf_get_lines(Debugging.panel.bufnr, 0, -1, true)

    if Debugging.panel and data ~= nil then
        if opts.header then
            if type(opts.header) == "string" then
                opts.header = { opts.footer }
            elseif type(opts.header) == "boolean" then
                opts.header = { "" }
            end
            utils.table_extend(result, opts.header)
        end
        -- append data
        Debugging.data = utils.table_extend(result, data)

        if opts.footer then
            if type(opts.footer) == "string" then
                opts.footer = { opts.footer }
            elseif type(opts.footer) == "boolean" then
                opts.footer = { "" }
            end
            utils.table_extend(result, opts.footer)
        end

        vim.api.nvim_buf_set_lines(Debugging.panel.bufnr, 0, -1, true, result)
    end
end

--- Render the panel
---@param bufnr any
---@param filepath any
function Debugging.render(bufnr, filepath)
    filepath = filepath or vim.fn.expand("%:p")

    if Debugging.panel == nil or Debugging.config.enabled == false then
        Debugging.close()
        return
    else
        Debugging.open()
    end

    Debugging.clear()

    Debugging.render_tools()
    Debugging.render_messages()
end

-- Tools

--- Append a tool to the panel
---@param tool table
function Debugging.append_tool(tool, opts)
    opts = opts or {}
    if type(tool) ~= "table" then
        return
    end

    local name = tool.name
    local status = tool.status

    Debugging.tools[#Debugging.tools + 1] = {
        name = name,
        status = status,
        message = opts.message
    }
end

--- Render the tools
function Debugging.render_tools()
    -- sort tools by name
    table.sort(Debugging.tools, function(a, b)
        return a.name < b.name
    end)

    local available_tools = {}
    -- TODO(geekmasher): some sort of symbol issue but this works
    local config = require("devsecinspect.config").config
    local enable_symbol = config.symbols.enabled
    local disable_symbol = config.symbols.disabled

    for _, tool in pairs(Debugging.tools) do
        local status = tool.status and enable_symbol or disable_symbol
        local msg = " -> " .. status .. " " .. tool.name

        if tool.message then
            msg = msg .. " [" .. tool.message .. "]"
        end

        available_tools[#available_tools + 1] = msg
    end
    -- add empty line
    Debugging.append_data(available_tools, {
        header = { "Setup Tools", "" },
        footer = true
    })
end

function Debugging.render_messages()
    local msgs = {}
    for _, msg in pairs(Debugging.messages) do
        msgs[#msgs + 1] = msg
    end

    Debugging.append_data(msgs, {
        header = { "Messages", "" },
        footer = true
    })
end

return Debugging
