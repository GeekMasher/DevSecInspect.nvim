local debugging    = require("devsecinspect.ui.panel")
local tools_panel  = require("devsecinspect.ui.tools")
local alerts_panel = require("devsecinspect.ui.alerts")

local alerts       = require("devsecinspect.alerts")
local cnf          = require("devsecinspect.config")

local M            = {}
M.tools            = {}

function M.setup(opts)
    opts = opts or {}

    -- Setup the Tools panel (always enabled)
    tools_panel.setup(opts)

    -- Setup the Alert
    alerts_panel.setup(opts)

    -- Create the Debugging Debugging panel
    if opts.debugging and opts.debugging.enabled == true then
        debugging.setup(opts)
    end
end

function M.open(name)
    if name == "tools" then
        tools_panel.create("DevSecInspect Tools", {}, { persistent = false })
    end
end

function M.clear(bufnr)
    alerts_panel.clear(bufnr)
end

--- Resize all panels
function M.on_resize()
    debugging.on_resize()
    alerts_panel.on_resize()
    tools_panel.on_resize()
end

function M.toggle()
    alerts_panel.toggle()
end

--- Refresh the UI
---@param bufnr integer | nil
---@param filepath string | nil
function M.render(bufnr, filepath)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    filepath = filepath or vim.api.nvim_buf_get_name(bufnr)

    -- TODO(geekmasher): do we need to check if this is a valid file buffer?

    -- alerts panel
    alerts_panel.render(bufnr)

    -- debugging panel
    debugging.render(filepath)
end

function M.refresh(bufnr, filepath)
    M.clear(bufnr)
    M.render(bufnr, filepath)
end

return M
