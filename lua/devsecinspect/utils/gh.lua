local commands = require("devsecinspect.utils.commands")

local GH = {}

--- Check if github is available
---@return boolean
function GH.status()
    return commands.check({ "gh", "auth", "status" })
end

function GH.login(opts)

end

--- Get REST API data from GitHub
---@param url string
---@param callback function
---@param opts table
function GH.get(url, callback, opts)
    callback = callback or function() end
    opts = opts or {}
    -- base params
    local params = {
        "api",
        "-H", "Accept: application/vnd.github+json",
        "-H", "X-GitHub-Api-Version: 2022-11-28",
        "--paginate"
    }
    table.insert(params, url)

    commands.run('gh', params, function(data)
        local json_data = vim.fn.json_decode(data)
        callback(json_data)
    end, opts)
end

return GH
