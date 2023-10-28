local cnf = require("devsecinspect.config")
local alerts = require("devsecinspect.alerts")
local panel = require("devsecinspect.ui.panel")
local ui = require("devsecinspect.ui")
local utils = require("devsecinspect.utils")
local config = require("devsecinspect.config")

local M = {}

--- Selected tools
--- @type table
M.selected = {}

-- list of tools
M.tools = {
    cargoaudit = {
        name = "cargo-audit",
        author = "RustSec",
        type = "sca",
        tool = require("devsecinspect.tools.cargoaudit")
    },
    -- SAST
    codeql = {
        name = "CodeQL",
        author = "GitHub",
        type = "sast",
        tool = require("devsecinspect.tools.codeql")
    },
    semgrep = {
        name = "Semgrep OSS",
        author = "Semgrep",
        type = "sast",
        tool = require("devsecinspect.tools.semgrep"),
    },
    -- Services
    github = {
        name = "GitHub Advanced Security",
        author = "GitHub",
        type = "service",
        tool = require("devsecinspect.tools.github"),
    },
}


--- Setup tools
---@param opts table
function M.setup(opts)
    opts = opts or {}
    local selected_tools = opts.tools or cnf.config.tools

    -- custom tools added
    if cnf.config.custom_tools ~= nil then
        utils.debug("Custom tools found")
        for tool_name, custom in pairs(cnf.config.custom_tools) do
            -- set name if not set
            if custom.name == nil then
                custom.name = tool_name
            end
            -- make sure tool is loaded correct
            if custom.tool == nil and type(custom.tool) == "table" then
                utils.error("Tool cannot be loaded correct: " .. tool_name)
                goto continue
            end

            M.tools[tool_name] = custom

            -- add to selected tools if not already added
            if selected_tools[tool_name] == nil then
                selected_tools[tool_name] = {}
            end
            ::continue::
        end
    end

    for tool_name, custom_config in pairs(selected_tools) do
        -- check if tool exists
        if not M.tools[tool_name] then
            utils.error("Tool not found: " .. tool_name)
            goto continue
        end

        local selected_tool = M.tools[tool_name]
        selected_tool.status = false

        utils.debug("Setting up and checking: " .. tool_name)

        -- run setup and pass custom config
        if selected_tool.tool.setup ~= nil then
            selected_tool.tool.setup(custom_config)
        end

        -- check the tool
        if selected_tool.tool.check ~= nil then
            -- print("Checking tool: " .. tool_name)
            selected_tool.status = selected_tool.tool.check()
        end

        -- append to panel
        panel.append_tool(selected_tool)

        ::continue::
    end

    ui.refresh()
end

function M.check_updates()

end

function M.install()

end

function M.analyse(bufnr, filepath, opts)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    filepath = filepath or vim.fn.expand("%:p")
    opts = opts or {}

    -- skip if buftype is not a file
    if vim.api.nvim_buf_get_option(bufnr, "buftype") ~= "" then
        return
    end
    -- set state for alerts
    alerts.bufnr = bufnr

    for tool_name, _ in pairs(cnf.config.tools) do
        local tool = M.tools[tool_name]
        tool.running = false

        -- check status
        if tool.status == false then
            utils.error("Tool status failed: " .. tool_name)
            goto continue
        end

        -- globs and languages from tool or config
        local globs = tool.tool.globs or tool.tool.config.globs
        local languages = tool.tool.languages or tool.tool.config.languages

        -- language check
        if languages and utils.match_language(bufnr, languages) == true then
            if tool.tool.run ~= nil then
                utils.info("Running tool: " .. tool_name)
                tool.running = true

                tool.tool.run(bufnr, filepath)
            else
                utils.error("Tool cannot be run: " .. tool_name)
            end
            -- glob check
        elseif globs and utils.match_globs(filepath, globs) then
            if tool.tool.run ~= nil then
                utils.info("Running tool: " .. tool_name)
                tool.running = true

                tool.tool.run(bufnr, filepath)
            else
                utils.error("Tool cannot be run: " .. tool_name)
            end
        end

        ::continue::
    end

    ui.refresh(filepath)
end

function M.run(bufnr, filepath)

end

--- Append a custom tool
---@param name any
---@param tool any
function M.append(name, tool)

end

return M
