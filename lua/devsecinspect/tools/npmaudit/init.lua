local Alert    = require("devsecinspect.alerts.alert")
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

--- Run npm-audit
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

    -- TODO(geekmasher): do we need to run `npm install` before running `npm audit`?

    commands.run(M.config.path, params, function(data)
        local json_data = vim.fn.json_decode(data)

        if json_data.vulnerabilities then
            -- generate list of locations of dependencies
            local locations = M.locations(bufnr, filepath)

            for dep_name, vulnerability in pairs(json_data.vulnerabilities) do
                local location = locations[dep_name]

                if location == nil then
                    location = { line = 0, column = 0, file = filepath }
                end

                for _, vuln_via in ipairs(vulnerability.via) do
                    local alert = Alert:new("npm-audit", vuln_via.title, location, {
                        severity = vuln_via.severity,
                        message = vuln_via.title,
                        references = {
                            vuln_via.url
                        }
                    })

                    alerts.add_alert(alert)
                end
            end
        else
            utils.debug("No vulnerabilities found")
        end
    end)
end

--- Find locations of dependencies in the buffer
---@param bufnr integer
---@param filepath string
---@return table
function M.locations(bufnr, filepath)
    -- find location of dependencies in the buffer
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local in_deps = false

    local results = {}

    for line_number, content in ipairs(lines) do
        if string.match(content, "[\"|\']dependencies[\"|\']:") then
            in_deps = true
        elseif in_deps == true and string.match(content, "^.*},?") then
            in_deps = false
        elseif in_deps == true then
            local dep = string.match(content, "[\"|\'](.*)[\"|\']:")
            local first_quote = string.find(content, "[\"|\']") or 0

            results[dep] = {
                line = line_number - 1,
                column = first_quote,
                column_end = #content,
                file = filepath,
                filename = vim.fn.fnamemodify(filepath, ":t")
            }
        end
    end

    return results
end

function M.fix(bufnr, filepath)
    commands.run(M.config.path, { "audit", "fix", "--force" }, function(data)
        utils.info("Auto-fixing npm audit vulnerabilities", { show = true })
        -- reload buffer
        vim.api.nvim_command("edit")

        -- run audit again
        local tools = require("devsecinspect.tools")
        tools.analyse(bufnr, filepath)
    end)
end

return M
