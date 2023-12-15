-- https://github.com/MunifTanjim/nui.nvim
local Popup = require "nui.popup"
local autocmd = require "nui.utils.autocmd"
local event = autocmd.event

local Tools = {}
Tools.panel = nil
Tools.bufnr = nil

Tools.alerts_panel_reopen = false

function Tools.setup(opts)
    opts = opts or {}
end

function Tools.create(name, data, opts)
    local config = require("devsecinspect.config").config
    data = data or {}
    opts = opts or {}

    local bufnr = vim.api.nvim_get_current_buf()

    if Tools.panel == nil then
        local panel = Popup {
            enter = true,
            focusable = true,
            relative = "win",
            border = {
                style = "rounded",
                text = {
                    top = " " .. name .. " ",
                },
            },
            position = {
                row = "30%",
                col = "30%",
            },
            size = {
                width = "70%",
                height = "70%",
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
                Tools.panel = nil
            end, { once = true })
        end

        Tools.panel = panel
        Tools.open()
    end
end

function Tools.on_resize() end

--- Open the panel
function Tools.open()
    if Tools.panel then
        local panel = require "devsecinspect.ui.panel"
        if panel.panel then
            Tools.alerts_panel_reopen = true
            panel.close()
        end
        Tools.panel:mount()
    end
end

--- Close the panel
function Tools.close()
    if Tools.panel then
        local panel = require "devsecinspect.ui.panel"
        if panel.panel and Tools.alerts_panel_reopen == true then
            Tools.alerts_panel_reopen = false
            panel.open()
        end
        Tools.panel:unmount()
    end
end

--- Clear the panel
function Tools.clear()
    if Tools.panel and Tools.panel.bufnr then
        vim.api.nvim_buf_set_lines(Tools.panel.bufnr, 0, -1, true, {})
    end
end

--- Update the panel on resize
function Tools.on_resize()
    if Tools.panel ~= nil then
        local config = require("devsecinspect.config").config
        Tools.panel:update_layout {
            size = {
                width = config.panel.size.width,
                height = config.panel.size.height,
            },
        }
    end
end

function Tools.render(opts)
    opts = opts or {}
    local tools = require "devsecinspect.tools"
end

return Tools
