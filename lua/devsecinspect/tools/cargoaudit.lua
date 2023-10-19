local utils    = require("devsecinspect.utils")
local commands = require("devsecinspect.utils.commands")
local alerts   = require("devsecinspect.alerts")
local config   = require("devsecinspect.config")
local panel    = require("devsecinspect.panel")

local M        = {}
M.name         = "cargo-audit"
M.config       = {}

--- Setup cargo-audit
---@param opts table
function M.setup(opts)
    local default = {
        path = "cargo-audit",
        globs = {
            "Cargo.toml"
        },
        languages = {
            "rust"
        }
    }
    M.config = utils.table_merge(default, opts or {})
end

--- Check if cargo-audit is installed
function M.check()
    return commands.check({ M.config.path, "--version" })
end

--- Run cargo-audit
---@param bufnr integer
---@param filepath string
function M.run(bufnr, filepath)
    -- use alerts cache
    if alerts.check_results("cargo-audit") then
        return
    end

    commands.run(M.config.path, { "audit", "--quiet", "--json" }, function(data)
        local json_data = vim.fn.json_decode(data)

        if json_data.vulnerabilities and json_data.vulnerabilities.count ~= 0 then
            -- only create locations if there are vulnerabilities
            local cargo_locations = M.create_locations(bufnr, filepath)

            for _, vulnerability in ipairs(json_data.vulnerabilities.list) do
                local location = M.find_top_level(vulnerability, cargo_locations)

                alerts.add_alert("cargo-audit", {
                    name = vulnerability.advisory.id,
                    location = location or {},
                    severity = M.check_severity(vulnerability.severity),
                    message = vulnerability.advisory.description,
                    reference = {}
                })
            end
        end

        panel.render()
    end)
end

--- Find the top level dependency in the tree
---@param vulnerability table
---@param cargo_locations table
---@return table
function M.find_top_level(vulnerability, cargo_locations)
    local package = vulnerability.package
    local dependency = package.name .. "@" .. package.version
    local cmd = { "cargo", "tree", "-e", "normal,build", "-i", dependency, "--prefix", "none" }
    local output = vim.fn.system(table.concat(cmd, " "))

    local dep_tree = {}

    -- TODO this is a bit hacky
    for line in vim.gsplit(output, "\n") do
        if line ~= "" then
            local dep = vim.split(line, " ")
            local dep_name = dep[1]
            local dep_version = dep[2]
            -- print("DEP :: " .. dep_name .. " :: " .. dep_version)

            if cargo_locations[dep_name] then
                return {
                    filepath = vim.fn.expand("%:p"),
                    line = cargo_locations[dep_name].line - 1,
                }
            else
                dep_tree[#dep_tree + 1] = dep_name
            end
        end
    end

    return { filepath = vim.fn.expand("%:p"), line = 0 }
end

--- Get the locations of the cargo dependencies
---@param bufnr number
---@param filepath string
---@return table
function M.create_locations(bufnr, filepath)
    -- top level dependencies (will be in the file)
    -- https://doc.rust-lang.org/cargo/commands/cargo-tree.html
    local cmd = { "cargo", "tree", "--depth", "1", "--format", "{p}", "--prefix", "none" }
    local output = vim.fn.system(table.concat(cmd, " "))

    local locations = {}
    local dependencies = {}

    for line in vim.gsplit(output, "\n") do
        if line ~= "" then
            table.insert(dependencies, line)
        end
    end

    -- TODO is this the best way to do this?
    -- find location of dependencies in the buffer
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    for line_number, line_content in ipairs(lines) do
        for _, dependency in ipairs(dependencies) do
            -- split by space
            local dep = vim.split(dependency, " ")
            local dep_name = dep[1]
            local dep_version = dep[2]

            -- print("DEP :: " .. dep_name .. " :: " .. dep_version)
            -- TODO check if this is the best way to do this
            if string.match(line_content, "^" .. dep_name) then
                -- print("LINE :: " .. line_content)
                locations[dep_name] = {
                    line = line_number,
                    version = dep_version,
                    text = line_content
                }
            end
        end
    end

    return locations
end

--- Check and update severity levels
---@param severity string
---@return string
function M.check_severity(severity)
    return severity
end

return M
