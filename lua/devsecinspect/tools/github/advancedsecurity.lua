local Alert = require "devsecinspect.alerts.alert"
local GH = require "devsecinspect.utils.gh"
local alerts = require "devsecinspect.alerts"
local utils = require "devsecinspect.utils"

local Packages = require "devsecinspect.utils.packages"

local M = {}
M.config = {}

--- Setup cargo-audit
---@param opts table
function M.setup(opts)
    local default = {
        path = "gh",
        dependabot = {
            enable = true,
        },
        codescanning = {
            enable = true,
        },
    }
    M.config = utils.table_merge(default, opts or {})
end

--- Check if github is available
---@return boolean
function M.check()
    return GH.status()
end

function M.run(bufnr, filepath)
    if M.config.dependabot.enable then
        M.run_dependabot(bufnr, filepath)
    end
    if M.config.codescanning.enable then
        M.run_codescanning(bufnr, filepath)
    end
end

--- Run GitHub Dependabot
---@param bufnr integer
---@param filepath string
function M.run_dependabot(bufnr, filepath)
    GH.get("/repos/{owner}/{repo}/dependabot/alerts", function(results)
        if #results == 0 then
            utils.debug "No alerts found"
            return
        end

        -- generate list of locations of dependencies for known package managers
        local packages = Packages:new(filepath)
        packages:load(bufnr, filepath)

        for _, dependabot_alert in ipairs(results) do
            local package = dependabot_alert.dependency.package.name

            -- location in the manifest file (might be the lock file)
            local location_file = M.find_package_file(dependabot_alert.dependency.manifest_path)

            local metadata = {
                description = dependabot_alert.description,
                severity = dependabot_alert.security_advisory.severity,
                references = {
                    dependabot_alert.html_url,
                },
            }
            local alert =
                Alert:new("dependabot", dependabot_alert.security_advisory.summary, packages:find(package), metadata)
            alerts.add_alert(alert)
        end
    end)
end

function M.run_codescanning(bufnr, filepath)
    local codescanning_alerts = GH.get "/repos/{owner}/{repo}/code-scanning/alerts"
end

--- Update / Patch location if needed
---@param location string
---@return string | nil
function M.find_package_file(location)
    if location == nil then
        utils.error "Location is required"
        return location
    end
    -- TODO(geekmasher): add extra mappings
    if location:match "package-lock.json" then
        return "package.json"
    end
    return location
end

return M
