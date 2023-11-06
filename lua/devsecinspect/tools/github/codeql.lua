local alerts = require("devsecinspect.alerts")
local utils = require("devsecinspect.utils")
local commands = require("devsecinspect.utils.commands")

local CodeQL = {}
CodeQL.languages = {
    "javascript",
    "python"
}
CodeQL.config = {}

--- Setup cargo-audit
---@param opts table
function CodeQL.setup(opts)
    local default = {
        path = "codeql",
        single_file = false,
        languages = {
            "javascript",
            "typescript",
            "python",
        }
    }
    CodeQL.config = utils.table_merge(default, opts or {})
end

function CodeQL.check()
    return commands.check({ CodeQL.config.path, "version", "--format", "terse" })
end

--- Run cargo-audit
---@param bufnr integer
---@param filepath string
function CodeQL.run(bufnr, filepath)
    local db_path = CodeQL.create_database(bufnr, filepath)
end

function CodeQL.create_database(bufnr, filepath)
    local tmpdir = vim.fn.tempname()
    local database_path = utils.join_paths(tmpdir, "codeql-database")

    local args = {
        "database",
        "create",
        "--language",
        "javascript",
        "--source-root",
        vim.fn.getcwd(),
        database_path
    }
    commands.run(CodeQL.config.path, args, function(data)
        print(data)
    end)
    return database_path
end

return CodeQL
