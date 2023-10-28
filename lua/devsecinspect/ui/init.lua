local panel = require("devsecinspect.ui.panel")
local cnf = require("devsecinspect.config")

local M = {}
M.tools = {}

function M.setup(opts)
    opts = opts or {}

    panel.create(cnf.name, {}, { persistent = true })
    if cnf.config.debug == true or opts.enabled then
        panel.render()
        panel.open()
    end
end

function M.refresh(filepath)
    panel.render(filepath)
end

return M
