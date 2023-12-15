local M = {}

M.name = "devsecinspect"
M.config = {}
M.tools = {}
M.ready = false

function M.setup(opts)
    local utils = require "devsecinspect.utils"
    local default = {
        -- Enable autocmd
        autocmd = true,
        -- List of tools to enable / use
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
        -- Alerts Display and Panel settings
        alerts = {
            -- Mode to display alerts
            mode = "summarised", -- "summarised" or "full"
            auto_open = false, -- automatically open the panel
            auto_close = false, -- automatically close the panel
            auto_preview = true, -- automatically preview alerts in the main buffer
            text_position = "eol", -- "eol" / "overlay" / "right_align" / "inline"
            panel = {
                enabled = false, -- always show the panel
                -- Panel position and size
                position = {
                    row = "0%",
                    col = "100%",
                },
                size = {
                    width = "30%",
                    height = "97%",
                },
            },
            -- Alert filters on when to display alerts
            filters = {
                -- Filter out alerts with severity below this level
                severity = "medium",
                -- Filter out alerts with confidence below this level
                confidence = nil,
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
            running = " ",
        },
        -- Debugging Panel config
        debugging = {
            enabled = false,
            panel = {
                enabled = false,
                position = {
                    row = "1%",
                    col = "99%",
                },
                size = {
                    width = "60%",
                    height = "98%",
                },
            },
        },
    }

    M.config = utils.table_merge(default, opts or {})

    if M.config.default_tools == true then
        M.config.tools["cargoaudit"] = {}
        M.config.tools["npmaudit"] = {}
    end
end

function M.get_symbol(name)
    if M.config.symbols == nil then
        return "[^]"
    end
    return M.config.symbols[name]
end

return M
