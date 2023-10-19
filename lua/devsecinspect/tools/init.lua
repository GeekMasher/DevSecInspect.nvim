local M = {}

-- SCA
M.cargoaudit = require("devsecinspect.tools.cargoaudit")

-- SAST
M.github = require("devsecinspect.tools.github")
M.semgrep = require("devsecinspect.tools.semgrep")

return M
