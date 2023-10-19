local utils = require("devsecinspect.utils")

local M = {}
M.name = "github"
M.config = {}

--- Setup cargo-audit
---@param opts table
function M.setup(opts)
    local default = {
        path = "github"
    }
    M.config = utils.table_merge(default, opts or {})
end

--- Check if github is available
---@return boolean
function M.check()
    -- TODO check if GitHub creds are available
    return false
end

function M.run(bufnr, filepath)

end

return M
