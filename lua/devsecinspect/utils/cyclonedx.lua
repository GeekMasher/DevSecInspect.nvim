local Alert = require "devsecinspect.alerts.alert"
local utils = require "devsecinspect.utils"

local M = {}

--- Load a file from disk and parse it into a table
---@param filepath string
---@param opts table
---@return table | nil
function M.load(filepath, opts)
    opts = opts or {}
    if utils.is_file(filepath) == false then
        return nil
    end

    local data = utils.read_file(filepath)

    local ok, result = pcall(vim.fn.json_decode, data)
    if not ok then
        return nil
    end

    return result
end

--- Parse and process a Cyclonedx file into a table of alerts
---@param filepath string
---@param opts table
---@return table | nil
function M.process(filepath, opts)
    opts = opts or {}
    local cyclonedx_data = M.load(filepath, opts)
    return M.processJson(cyclonedx_data, filepath, opts)
end

function M.processJson(cyclonedx_data, filepath, opts)
    if cyclonedx_data == nil or type(cyclonedx_data) ~= "table" then
        utils.warning("Failed to parse CycloneDX file: " .. filepath)
        return nil
    end

    if cyclonedx_data["bomFormat"] ~= "CycloneDX" then
        utils.warning("Failed to parse CycloneDX file: " .. filepath)
        return nil
    end

    -- locations of dependencies in the file
    local locations = opts.locations or {}
    -- build a table of all the components in the bom
    local components = {}
    for i, comp in ipairs(cyclonedx_data["components"]) do
        components[comp["bom-ref"]] = comp["name"]
    end

    for i, vulnerability in ipairs(cyclonedx_data.vulnerabilities) do
        -- lookup the component name from the bom-ref
        local bomref = vulnerability["bom-ref"]
        local depname = components[bomref]
        local location = locations[depname] or {}

        local alert = Alert:new("pip-audit", vulnerability["id"], location, {})

        table.insert(results, alert)
    end

    return results
end

return M
