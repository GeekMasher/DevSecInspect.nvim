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
        utils.error("Tool, name, and location are required")
        return {}
    end
    if not location.file or not location.line then
        utils.error("Alert missing required `location.file` or `location.line` field")
        return {}
    end

    local alert = setmetatable({}, Alert)

    alert.tool = tool
    alert.name = name
    -- default: first line in the file
    alert.location = location or { line = 1, column = 0 }

    if alert.location.file ~= nil and alert.location.filename == nil then
        alert.location.filename = vim.fn.fnamemodify(alert.location.file, ":t")
    end

    -- optional properties
    alert.message = opts.message
    -- lookup and set severity level based on NIST standards
    alert.severity = Alert:lookup_severity(opts.severity)
    alert.category = opts.category or name
    alert.paths = opts.paths or {}
    alert.references = opts.references or {}

    -- if multiple locations are provided, add them to the alert
    alert.locations = opts.locations or {}

    return alert
end

--- Get instance of the alert
---@return string
function Alert:get_instance()
    if self.location.filename == nil then
        return self.location.file .. "#" .. self.location.line
    elseif self.location.column then
        return self.location.filename .. "#" .. self.location.line .. "#" .. self.location.column
    else
        return self.location.filename .. "#" .. self.location.line
    end
end

--- Get compiler-based severity level
---@return string
function Alert:get_severity_level()
    -- https://neovim.io/doc/user/diagnostic.html#vim.diagnostic.severity
    if self.severity == "critical" or self.severity == "high" then
        return vim.diagnostic.severity.Error
    elseif self.severity == "medium" then
        return vim.diagnostic.severity.Warning
    elseif self.severity == "low" or self.severity == "info" then
        return vim.diagnostic.severity.Information
    else
        return vim.diagnostic.severity.Hint
    end
end

--- Lookup and return the severity level of the alert
---@param severity string | nil
---@return string
function Alert:lookup_severity(severity)
    severity = severity or "unknown"
    -- lowercase severity
    severity = string.lower(severity)
    --
    if severity == "critical" or severity == "very-high" then
        return "critical"
    elseif severity == "high" or severity == "error" then
        return "high"
    elseif severity == "medium" or severity == "moderate" or severity == "warning" then
        return "medium"
    elseif severity == "low" then
        return "low"
    elseif severity == "info" or severity == "very-low" then
        return "info"
    else
        return "unknown"
    end
end

return Alert
