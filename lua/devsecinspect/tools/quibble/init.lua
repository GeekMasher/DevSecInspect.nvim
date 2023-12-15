local alerts = require "devsecinspect.alerts"
local commands = require "devsecinspect.utils.commands"
local sarif = require "devsecinspect.utils.sarif"
local utils = require "devsecinspect.utils"

local M = {}
M.config = {}
M.globs = {
    "docker%-compose%.yml$",
}

function M.setup(opts)
    local default = {
        path = "quibble",
        filter = "all",
    }
    M.config = utils.table_merge(default, opts or {})
end

function M.check()
    return commands.check { M.config.path, "--version" }
end

function M.run(bufnr, filepath)
    local sarif_file = vim.fn.tempname()
    local args = {
        "compose",
        "-f",
        M.config.filter,
        "--format",
        "sarif",
        "--output",
        sarif_file,
        "-p",
        filepath,
    }
    utils.debug("Running quibble with args: " .. vim.inspect(args))

    commands.run(M.config.path, args, function(data)
        utils.debug "Quibble has results"

        local results = sarif.process(sarif_file, {})
        if not results then
            utils.error "No results from quibble"
            return
        end

        alerts.extend("quibble", results)
    end)
end

return M
