local utils = require('devsecinspect.utils')

local M = {}
M.engine = "docker"

function M.check(image, opts)
    opts = opts or {}

    local cmd = { M.engine, "image", "inspect", image }

    print("Checking: " .. table.concat(cmd, " "))
    return utils.check_command(cmd)
end

function M.run(image, opts)
    opts = opts or {}

    local cmd = { M.engine, "run", "--rm" }

    -- volumes
    for _, volume in ipairs(opts.volumes or {}) do
        cmd[#cmd + 1] = "-v"
        cmd[#cmd + 1] = volume
    end

    cmd[#cmd + 1] = image

    print("Running: " .. table.concat(cmd, " "))
end

return M
