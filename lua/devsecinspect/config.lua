local M = {}

M.name = "devsecinspect"
M.config = {}
M.tools = {}
M.ready = false

function M.setup(opts)
    local utils = require("devsecinspect.utils")
    local default = {
        -- Debugging mode
        debug = false,
        -- Enable autocmd
        autocmd = true,
        -- Tools
        tools = {},
        default_tools = true,
        -- Custom Tools
        custom_tools = {},
        -- Auto-fix
        autofix = {
            enable = false,
            ai_enable = false,
            ai_tool = "copilot",
        },
        -- Panel config
        panel = {
            enable = false,
            position = {
                row = "0%",
                col = "100%"
            },
            size = {
                width = "30%",
                height = "97%",
            },
        },
        symbols = {
            -- Icons
            info = " ",
            debug = " ",
            error = " ",
            warning = " ",
            hint = " ",
            -- Statuses
            enabled = "",
            disabled = "",
            running = "",
        }
    }

    M.config = utils.table_merge(default, opts or {})

    if M.config.default_tools == true then
        M.config.tools["cargoaudit"] = {}
        M.config.tools["npmaudit"] = {}
    end
end

return M
