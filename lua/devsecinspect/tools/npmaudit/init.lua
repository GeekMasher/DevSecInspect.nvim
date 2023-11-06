local alerts   = require("devsecinspect.alerts")
local utils    = require("devsecinspect.utils")
local commands = require("devsecinspect.utils.commands")

local M        = {}
M.globs        = {
    "package.json"
}
M.config       = {}

--- Setup cargo-audit
---@param opts table
function M.setup(opts)
    local default = {
        path = "npm",
        globs = {
            "package.json"
        },
        level = "high",
        omit = "dev"
    }
    M.config = utils.table_merge(default, opts or {})
end

function M.check()
    return commands.check({ M.config.path, "audit", "--help" })
end

--- Run cargo-audit
---@param bufnr integer
---@param filepath string
function M.run(bufnr, filepath)
    -- use alerts cache
    if alerts.check_results("npm-audit") then
        return
    end

    -- parameters
    local params = { "audit", "--json" }

    if M.config.omit ~= nil then
        table.insert(params, "--omit")
        table.insert(params, M.config.omit)
    end
    if M.config.level ~= nil then
        table.insert(params, "--audit-level")
        table.insert(params, M.config.level)
    end

    commands.run(M.config.path, params, function(data)
        local json_data = vim.fn.json_decode(data)

        if json_data.vulnerabilities then
            for dep_name, vulnerability in pairs(json_data.vulnerabilities) do
                local location = M.find_location(bufnr, dep_name)

                for _, vuln_via in ipairs(vulnerability.via) do
                    alerts.append("npm-audit", {
                        name = vuln_via.title,
                        location = location or {},
                        severity = vuln_via.severity,
                        message = vuln_via.title .. " - " .. vuln_via.url,
                        reference = {}
                    })
                end
            end
        else
            utils.debug("No vulnerabilities found")
        end
    end)
end

function M.find_location(bufnr, dep_name)
    -- find location of dependencies in the buffer
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    for line_number, line_content in ipairs(lines) do
        if string.match(line_content, "^.*\"" .. dep_name .. "\":") then
            return {
                line = line_number - 1,
            }
        end
    end
    return {}
end

return M
