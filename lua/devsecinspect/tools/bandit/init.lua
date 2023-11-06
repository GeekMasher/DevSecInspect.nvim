local alerts   = require("devsecinspect.alerts")
local utils    = require("devsecinspect.utils")
local commands = require("devsecinspect.utils.commands")

local M        = {}
M.languages    = { "python" }
M.config       = {}

--- Setup cargo-audit
---@param opts table
function M.setup(opts)
    local default = {
        path = "bandit",
        languages = { "python" },
    }
    M.config = utils.table_merge(default, opts or {})
end

function M.check()
    return commands.check({ M.config.path, "--version" })
end

--- Run cargo-audit
---@param bufnr integer
---@param filepath string
function M.run(bufnr, filepath)
    -- reset alerts as bandit is very fast
    alerts.reset(bufnr)

    commands.run(M.config.path, { "-f", "json", "-q", filepath }, function(data)
        local json_data = vim.fn.json_decode(data)

        if json_data.results then
            for _, vulnerability in ipairs(json_data.results) do
                local location = {
                    line = vulnerability.line_number - 1,
                }

                alerts.append("bandit", {
                    name = vulnerability.test_name,
                    location = location or {},
                    severity = vulnerability.issue_severity,
                    message = vulnerability.issue_text,
                    reference = {
                        id = vulnerability.test_name,
                    }
                })
            end
        else
            utils.debug("No vulnerabilities found")
        end
    end)
end

return M
