local M = {}

M.name = "devsecinspect"
M.config = {}
M.tools = {}
M.ready = false

function M.setup(opts)
    local utils = require("devsecinspect.utils")
    local default = {
        autocmd = true,
        tools = {},
        panel = {
            enable = false
        },
        symbols = {
            error = " ",
            warning = " ",
            info = " ",
            hint = " "
        }
    }

    M.config = utils.table_merge(default, opts or {})
end

return M
