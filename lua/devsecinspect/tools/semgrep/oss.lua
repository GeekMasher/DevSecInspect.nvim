local utils      = require("devsecinspect.utils")
local commands   = require("devsecinspect.utils.commands")
local containers = require("devsecinspect.utils.containers")
local sarif      = require("devsecinspect.utils.sarif")
local alerts     = require("devsecinspect.alerts")

local M          = {}
-- Languages supported by semgrep
-- https://semgrep.dev/docs/supported-languages/#language-maturity
---@type table
M.languages      = {
    "python",
    "javascript",
    "typescript",
    "go",
    "java",
    "php",
    "ruby",
    "scala",
}
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
        rules = {
            config = "p/default",
        },
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

function M.run(bufnr, filepath)
    if M.config.container.enabled then
        utils.error("Running semgrep in container isn't currently supported...")
    else
        M.run_cli(bufnr, filepath)
    end
end

function M.run_cli(bufnr, filepath)
    local sarif_file = vim.fn.tempname()
    local rules_config = M.config.rules.config or "auto"
    local args = {
        "--config", rules_config, "--sarif", "--output", sarif_file, filepath
    }
    utils.debug("Running semgrep with args: " .. vim.inspect(args))

    commands.run(M.config.path, args, function(data)
        utils.info("Semgrep has results")
        -- results from sarif file
        local pre_results = sarif.process(sarif_file, {})
        if not pre_results then
            utils.error("No results from semgrep")
            return
        end

        local simple_list = {}
        local results = {}

        -- post-sarif processing for semgrep
        -- IDs/Names are not unique, so we need them filter some out
        for _, result in ipairs(pre_results) do
            -- simplify the name of the alert
            local split_name = utils.split(result.name, ".")
            result.name = M.find_alias(split_name[#split_name])

            local simple_name = result.name .. "#" .. result.location.line
            utils.debug("Split alert name: " .. simple_name)

            -- check if name is already in simple_list
            if utils.contains(simple_name, simple_list) == false then
                -- add to simple_list
                simple_list[#simple_list + 1] = simple_name

                utils.debug("Adding alert: " .. result.name)
                results[#results + 1] = result
            else
                utils.debug("Alert already exists: " .. result.name)
            end
        end

        alerts.extend("semgrep", results)
    end)

    return sarif_file
end

-- Semgrep results can have multiple ids/names for the "same alert"
-- This is a list of aliases to the correct rule name to help
-- with deduplication
M.rule_aliases = {
    ["sqlalchemy-execute-raw-query"] = "tainted-sql-string"
}
--- Find the correct rule name for an alias or return the original name
---@param rulealias string
---@return string
function M.find_alias(rulealias)
    if M.rule_aliases[rulealias] then
        utils.info("Found alias: " .. rulealias)
        return M.rule_aliases[rulealias]
    end
    return rulealias
end

return M
