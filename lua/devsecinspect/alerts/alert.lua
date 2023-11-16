local utils = require("devsecinspect.utils")

local Alert = {}
Alert.__index = Alert

--- Create a new alert
---@param tool string
---@param name string
---@param location table
---@param opts table | nil
---@return table
function Alert:new(tool, name, location, opts)
    opts = opts or {}

    -- validation
    if tool == nil or name == nil or location == nil then
        utils.error("Tool, name, location, and severity is required")
        return
    end
    if not location.line then
        utils.error("Alert missing required `location.line` field")
        return
    end

    local alert = setmetatable({}, Alert)

    alert.tool = tool
    alert.name = name
    -- default: first line in the file
    alert.location = location or { line = 1, column = 0 }


    -- optional properties
    alert.message = opts.message
    alert.severity = opts.severity or "Unknown"
    alert.category = opts.category or "Unknown"
    alert.paths = opts.paths or {}

    return alert
end

return Alert
