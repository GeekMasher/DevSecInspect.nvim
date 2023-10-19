local utils      = require("devsecinspect.utils")
local commands   = require("devsecinspect.utils.commands")
local containers = require("devsecinspect.utils.containers")

local M          = {}
M.name           = "semgrep"
M.config         = {}


function M.setup(opts)
    opts = opts or {}
    local default = {
        -- semgrep path
        path = "semgrep",
        container = {
            enabled = false,
            engine = "docker",
            image = "returntocorp/semgrep:latest",
        },
        -- semgrep config
        config = {
            rules = "auto",
        },
        -- semgrep languages
        languages = {
            "rust"
        }
    }
    M.config = utils.table_merge(default, opts or {})
end

--- Check if semgrep is installed
---@return boolean
function M.check()
    if M.config.container.enabled then
        return containers.check(M.config.setup.image)
    else
        return commands.check({ M.config.path, "--version" })
    end
end

function M.install()

end

function M.run(filepath)

end

return M
