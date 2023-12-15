local alerts = require "devsecinspect.alerts"
local cnf = require "devsecinspect.config"
local config = require "devsecinspect.config"
local panel = require "devsecinspect.ui.panel"
local ui = require "devsecinspect.ui"
local utils = require "devsecinspect.utils"

local M = {}
M.running = false

--- Selected tools
--- @type table
M.selected = {}

-- list of tools
M.tools = {
    cargoaudit = {
        name = "Cargo Audit",
        author = "RustSec",
        type = "sca",
        tool = require "devsecinspect.tools.cargoaudit",
    },
    npmaudit = {
        name = "NPM Audit",
        author = "npm",
        type = "sca",
        tool = require "devsecinspect.tools.npmaudit",
    },
    -- SAST
    codeql = {
        name = "CodeQL",
        author = "GitHub",
        type = "sast",
        tool = require "devsecinspect.tools.github.codeql",
    },
    bandit = {
        name = "Bandit",
        author = "PyCQA",
        type = "sast",
        tool = require "devsecinspect.tools.bandit",
    },
    semgrep = {
        name = "Semgrep OSS",
        author = "Semgrep",
        type = "sast",
        tool = require "devsecinspect.tools.semgrep.oss",
    },
    quibble = {
        name = "Quibble",
        author = "GeekMasher",
        type = "sast",
        tool = require "devsecinspect.tools.quibble",
    },
    -- Services
    github = {
        name = "GitHub Advanced Security",
        author = "GitHub",
        type = "service",
        tool = require "devsecinspect.tools.github.advancedsecurity",
    },
}

--- Setup tools
---@param opts table
function M.setup(opts)
    opts = opts or {}
    local selected_tools = opts.tools or cnf.config.tools

    -- custom tools added
    if cnf.config.custom_tools ~= nil then
        utils.debug "Custom tools found"
        for tool_name, custom in pairs(cnf.config.custom_tools) do
            -- set name if not set
            if custom.name == nil then
                custom.name = tool_name
            end
            -- make sure tool is loaded correct
            if custom.tool ~= nil and type(custom.tool) ~= "table" then
                M.tools[tool_name] = custom

                -- add to selected tools if not already added
                if selected_tools[tool_name] == nil then
                    selected_tools[tool_name] = {}
                end
            else
                utils.error("Tool cannot be loaded correct: " .. tool_name)
            end
        end
    end

    for tool_name, custom_config in pairs(selected_tools) do
        -- check if tool exists
        if M.tools[tool_name] then
            local selected_tool = M.tools[tool_name]

            selected_tool.status = false -- tool is ready to run
            selected_tool.running = false -- tool is running
            selected_tool.available = false -- tool is available for current file

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

            -- update tool
            M.tools[tool_name] = selected_tool

            -- append to panel
            panel.append_tool(selected_tool)
        else
            utils.error("Tool not found: " .. tool_name)
        end
    end

    ui.refresh()
end

function M.check_updates() end

function M.install() end

--- Analyse file
---@param bufnr number
---@param filepath string
---@param opts table | nil
function M.analyse(bufnr, filepath, opts)
    if M.running == true then
        utils.debug "analyse is already running, skipping"
        return
    end

    bufnr = bufnr or vim.api.nvim_get_current_buf()
    filepath = filepath or vim.api.nvim_buf_get_name(bufnr)
    opts = opts or {}

    -- skip if buftype is not a file
    if vim.api.nvim_buf_get_option(bufnr, "buftype") ~= "" then
        return
    elseif filepath == nil or filepath == "" then
        return
    end

    M.running = true

    local filename = vim.fn.fnamemodify(filepath, ":t")
    utils.debug("Analysing file: " .. filename, { show = true })

    -- reset diagnostics
    -- TODO(geekmasher): what about multi-file analysis?
    alerts.clear()
    ui.clear(bufnr)

    -- set state for alerts
    alerts.bufnr = bufnr

    for tool_name, _ in pairs(cnf.config.tools) do
        local tool = M.tools[tool_name]

        -- check status
        if tool.status == false then
            utils.error("Tool status failed: " .. tool_name)
        elseif tool.running == true then
            -- check if tool is running
            utils.warning("Tool is already running: " .. tool_name)
        else
            -- globs and languages from tool or config
            local globs = tool.tool.globs or tool.tool.config.globs
            local languages = tool.tool.languages or tool.tool.config.languages

            -- language check
            if languages and utils.match_language(bufnr, languages) == true then
                M.tools[tool_name].available = true

                if tool.tool.run ~= nil then
                    utils.debug("Running tool: " .. tool_name, { show = true })
                    M.tools[tool_name].running = true

                    ui.render()

                    tool.tool.run(bufnr, filepath)
                    M.tools[tool_name].running = false
                    ui.render()
                else
                    utils.error("Tool cannot be run: " .. tool_name)
                end
                -- glob check
            elseif globs and utils.match_globs(filepath, globs) then
                M.tools[tool_name].available = true

                if tool.tool.run ~= nil then
                    utils.info("Running tool: " .. tool_name)
                    M.tools[tool_name].running = true

                    ui.render()

                    tool.tool.run(bufnr, filepath)

                    M.tools[tool_name].running = false
                    ui.render()
                else
                    utils.debug("Tool cannot be run: " .. tool_name)
                end
            elseif tool.type == "service" then
                -- if the tool is a service always run it
                -- this is because the service will check the file
                if tool.tool.run ~= nil then
                    utils.info("Running tool: " .. tool_name)
                    M.tools[tool_name].running = true

                    ui.render()

                    tool.tool.run(bufnr, filepath)

                    M.tools[tool_name].running = false
                    ui.render()
                end
            end
        end
    end

    M.running = false
    ui.render()
end

function M.run(bufnr, filepath) end

--- Fix security alert if possible
---@param bufnr integer
---@param filepath string
function M.fix(bufnr, filepath, opts)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    filepath = filepath or vim.fn.expand "%:p"
    opts = opts or {}

    for tool_name, _ in pairs(cnf.config.tools) do
        local tool = M.tools[tool_name]

        -- globs and languages from tool or config
        local globs = tool.tool.globs or tool.tool.config.globs
        local languages = tool.tool.languages or tool.tool.config.languages

        -- language check
        if languages and utils.match_language(bufnr, languages) == true then
            M.tools[tool_name].available = true

            if tool.tool.fix ~= nil then
                utils.info("Fixing tool: " .. tool_name)
                tool.tool.fix(bufnr, filepath)
            else
                utils.error("Tool cannot be fixed: " .. tool_name)
            end
        elseif globs and utils.match_globs(filepath, globs) then
            M.tools[tool_name].available = true

            if tool.tool.fix ~= nil then
                utils.info("Fixing tool: " .. tool_name)
                tool.tool.fix(bufnr, filepath)
            else
                utils.error("Tool cannot be fixed: " .. tool_name)
            end
        end
    end
end

--- Autofix security alert if possible
---@param bufnr integer
---@param filepath string
function M.autofix(bufnr, filepath, opts)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    filepath = filepath or vim.fn.expand "%:p"
    opts = opts or {}

    -- check config
    if cnf.config.autofix ~= nil and cnf.config.autofix.enabled == false then
        utils.error "Autofix is disabled"
        return
    end

    for _, alert in pairs(alerts.alerts) do
        if cnf.config.autofix.ai_enabled == true then
            -- AI autofix
            utils.error "AI is not implemented yet"
        else
            -- Run the tools autofix function (if available)
            local tool = M.tools[alert.tool]
            if tool == nil then
                utils.error("Tool not found: " .. alert.tool)
                return
            end

            if tool.tool.autofix ~= nil then
                tool.tool.autofix(bufnr, filepath, alert)
            else
                utils.error("Tool cannot be autofixed: " .. alert.tool)
            end
        end
    end
end

--- Append a custom tool
---@param name any
---@param tool any
function M.append(name, tool) end

return M
