local ui = require("devsecinspect.ui")
local panel = require("devsecinspect.ui.panel")
local config = require("devsecinspect.config")
local utils = require("devsecinspect.utils")

local CMD = {}


--- Check if a command exists / works
---@param cmd table
---@param opts table | nil
---@return boolean
function CMD.check(cmd, opts)
    opts = opts or {}
    local c = table.concat(cmd, " ")
    local output = vim.fn.system(c)

    if not output then
        return false
    end
    return true
end

--- Run a command (background)
---@param command string
---@param args table
---@param callback function | nil
---@param opts table | nil
function CMD.run(command, args, callback, opts)
    opts = opts or {}
    callback = callback or function()
        panel.render_tools()
    end

    local cmd = { command }

    -- args
    for _, arg in ipairs(args or {}) do
        cmd[#cmd + 1] = arg
    end

    if opts.foreground then
        utils.debug("Running in foreground: " .. command)
        vim.schedule(function()
            local data = vim.fn.system(cmd)
            callback(_, data)
        end)
        return
    else
        local stdout = vim.loop.new_pipe(false)
        vim.fn.jobstart(cmd, {
            stdout_buffered = true,
            on_stdout = function(_, data, _)
                if not data then
                    return
                end

                callback(data)
                ui.render()
            end
        })
    end
end

return CMD
