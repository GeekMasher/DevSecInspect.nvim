local cnf    = require("devsecinspect.config")
local tools  = require("devsecinspect.tools")
local utils  = require("devsecinspect.utils")
local ui     = require("devsecinspect.ui")
local panel  = require("devsecinspect.ui.panel")
local alerts = require("devsecinspect.alerts")

local M      = {}

---comment
---@param opts table
function M.setup(opts)
    cnf.setup(opts or {})

    -- setup ui and tools
    ui.setup(cnf.config.panel)
    tools.setup({
        tools = cnf.config.tools
    })
    -- refresh ui
    ui.refresh()

    -- setup autocmd
    if cnf.config.autocmd then
        local group = vim.api.nvim_create_augroup(cnf.name, { clear = true })
        vim.api.nvim_create_autocmd({ "BufEnter" }, {
            group = group,
            callback = function()
                vim.schedule(function()
                    tools.analyse()
                end)
            end
        })
        -- on post write
        vim.api.nvim_create_autocmd({ "BufWritePost" }, {
            group = group,
            callback = function()
                vim.schedule(function()
                    -- Clear alerts and re-run analysis
                    alerts.reset()
                    tools.analyse()
                end)
            end
        })
    end

    -- Commands
    vim.api.nvim_create_user_command("DSI", function()
        tools.analyse()
    end, {})
end

return M
