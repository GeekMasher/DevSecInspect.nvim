local Pip = require "devsecinspect.utils.packages.pip"
local alerts = require "devsecinspect.alerts"
local commands = require "devsecinspect.utils.commands"
local cyclonedx = require "devsecinspect.utils.cyclonedx"
local utils = require "devsecinspect.utils"

local M = {}
M.globs = {
    "requirements.txt",
}
M.config = {}

--- Setup cargo-audit
---@param opts table
function M.setup(opts)
    local default = {
        path = "pip-audit",
        globs = {
            "requirements.txt",
        },
    }
    M.config = utils.table_merge(default, opts or {})
end

function M.check()
    return commands.check { M.config.path, "--version" }
end

--- Run npm-audit
---@param bufnr integer
---@param filepath string
function M.run(bufnr, filepath)
    -- use alerts cache
    if alerts.check_results "pip-audit" then
        return
    end

    -- temporary file
    local tmpfile = vim.fn.tempname()
    -- parameters
    local params = { "-f", "cyclonedx-json", "-l", "-r", filepath, "-o", tmpfile, "--no-deps", "--disable-pip" }

    commands.run(M.config.path, params, function(data)
        local locations = Pip:locations(bufnr, filepath)
        local cyclonedx_alerts = cyclonedx.process(tmpfile, { locations = locations })

        print(vim.inspect(cyclonedx_alerts))
        alerts.extend("pip-audit", cyclonedx_alerts)
    end)
end

function M.fix(bufnr, filepath)
    commands.run(M.config.path, { "audit", "fix", "--force" }, function(data)
        utils.info("Auto-fixing npm audit vulnerabilities", { show = true })
        -- reload buffer
        vim.api.nvim_command "edit"

        -- run audit again
        local tools = require "devsecinspect.tools"
        tools.analyse(bufnr, filepath)
    end)
end

return M
