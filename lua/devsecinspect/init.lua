local cnf    = require("devsecinspect.config")
local tools  = require("devsecinspect.tools")
local utils  = require("devsecinspect.utils")
local ui     = require("devsecinspect.ui")
local alerts = require("devsecinspect.alerts")

local M      = {}

---comment
---@param opts table
function M.setup(opts)
    cnf.setup(opts or {})

    -- setup ui and tools
    ui.setup(cnf.config)
    tools.setup({
        tools = cnf.config.tools
    })

    -- refresh ui
    ui.render()

    -- setup autocmd
    local group = vim.api.nvim_create_augroup(cnf.name, { clear = true })

    -- on resize
    vim.api.nvim_create_autocmd({ "WinResized" }, {
        group = group,
        callback = function()
            vim.schedule(function()
                ui.on_resize()
            end)
        end
    })


    if cnf.config.autocmd then
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
    vim.api.nvim_create_user_command("DSIInstall", function()
        ui.open("tools")
    end, {})
end

return M
