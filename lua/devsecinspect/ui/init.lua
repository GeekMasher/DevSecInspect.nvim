local panel = require("devsecinspect.ui.panel")
local tools_panel = require("devsecinspect.ui.tools")
local cnf = require("devsecinspect.config")

local M = {}
M.tools = {}

function M.setup(opts)
    opts = opts or {}

    -- Setup the Tools panel
    tools_panel.setup(opts)

    -- Create the Alert panel
    panel.create(cnf.name, {}, { persistent = true })
    if cnf.config.debug == true or opts.enabled then
        panel.render()
        panel.open()
    end
end

function M.open(name)
    if name == "tools" then
        tools_panel.create("DevSecInspect Tools", {}, { persistent = false })
    end
end

--- Resize all panels
function M.on_resize()
    panel.on_resize()
    tools_panel.on_resize()
end

function M.refresh(filepath)
    panel.render(filepath)
end

return M
