local PackageJson = require("devsecinspect.utils.packages.packagejson")

local Packages = {}
Packages.__index = Packages

function Packages:new(filepath)
    local package = {}
    setmetatable(package, Packages)

    package.filepath = filepath
    package.locations = {}

    return package
end

--- Load packages
---@param bufnr any
---@param filepath any
---@return table
function Packages:load(bufnr, filepath)
    if filepath:match("package.json") then
        self.locations = PackageJson:locations(bufnr, filepath)
    end
    return {}
end

--- Find package by name
---@param package string
function Packages:find(package)
    if package == nil then
        return { file = self.filepath, line = 0, column = 0 }
    end

    if self.locations[package] then
        return { file = self.filepath, line = self.locations[package].line, column = self.locations[package].column }
    end

    return { file = self.filepath, line = 0, column = 0 }
end

return Packages
