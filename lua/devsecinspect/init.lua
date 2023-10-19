local cnf    = require("devsecinspect.config")
local tools  = require("devsecinspect.tools")
local utils  = require("devsecinspect.utils")
local panel  = require("devsecinspect.panel")
local alerts = require("devsecinspect.alerts")

local M      = {}

---comment
---@param opts table
function M.setup(opts)
    cnf.setup(opts or {})

    -- setup panel
    panel.create_panel(cnf.name, {}, { persistent = true })
    if cnf.config.debug == true then
        panel.render()
        panel.open()
    end

    vim.schedule(function()
        -- setup all available tools
        -- get tool name
        for _, tool in pairs(tools) do
            if tool.setup ~= nil then
                tool.setup()
            end
            if tool.check ~= nil then
                tool.status = tool.check()
            else
                tool.status = false
            end

            panel.append_tool(tool.name, tool.status)
        end
        panel.render()
    end)

    -- check config
    for tool_name, tool_config in pairs(cnf.config.tools) do
        if not tools[tool_name] then
            cnf.config.tools[tool_name] = nil
            vim.api.nvim_err_writeln("Tool not found: " .. tool_name)
        end
    end

    -- setup autocmd
    if cnf.config.autocmd then
        local group = vim.api.nvim_create_augroup(cnf.name, { clear = true })
        vim.api.nvim_create_autocmd({ "BufEnter" }, {
            group = group,
            callback = function()
                vim.schedule(function()
                    M.analyse()
                end)
            end
        })
        -- on post write
        vim.api.nvim_create_autocmd({ "BufWritePost" }, {
            group = group,
            callback = function()
                vim.schedule(function()
                    -- Clear alerts and re-run analysis
                    alerts.reset()
                    M.analyse()
                end)
            end
        })
    end

    -- Commands
    vim.api.nvim_create_user_command("DSI", function()
        M.analyse()
    end, {})
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
        local tool = tools[tool_name]
        -- check status
        if tool.status == false then
            vim.api.nvim_err_writeln("Tool not installed: " .. tool_name)
            return
        end

        -- language check
        if tool.languages then
            if utils.match_language(bufnr, tool.languages) == true then
                tools[tool_name].run(bufnr, filepath)
            end
        end
        -- glob check
        local globs = tools[tool_name].config.globs or {}
        if utils.match_globs(filepath, globs) then
            tools[tool_name].run(bufnr, filepath)
        end
    end

    panel.render(filepath)
end

return M
