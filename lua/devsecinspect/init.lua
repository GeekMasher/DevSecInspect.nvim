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
                    local bufnr = vim.api.nvim_get_current_buf()
                    local filepath = vim.api.nvim_buf_get_name(bufnr)
                    tools.analyse(bufnr, filepath)
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

                    local bufnr = vim.api.nvim_get_current_buf()
                    local filepath = vim.api.nvim_buf_get_name(bufnr)
                    tools.analyse(bufnr, filepath)
                end)
            end
        })
    end

    -- Commands
    vim.api.nvim_create_user_command("DSI", function()
        -- toggle ui
        ui.toggle()

        local bufnr = vim.api.nvim_get_current_buf()
        local filepath = vim.api.nvim_buf_get_name(bufnr)
        tools.analyse(bufnr, filepath)
    end, {})

    vim.api.nvim_create_user_command("DSIInstall", function()
        ui.open("tools")
    end, {})

    vim.api.nvim_create_user_command("DSIFix", function()
        local bufnr = vim.api.nvim_get_current_buf()
        local filepath = vim.api.nvim_buf_get_name(bufnr)
        tools.fix(bufnr, filepath)
    end, {})
end

return M
