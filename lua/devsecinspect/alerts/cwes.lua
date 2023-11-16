local M = {}

M.cwes = {
    ["CWE-20"] = "Improper Input Validation",
    ["CWE-22"] = "Path Traversal",
    ["CWE-78"] = "OS Command Injection",
    ["CWE-79"] = "Cross-site Scripting (XSS)",
    ["CWE-89"] = "SQL Injection",
    ["CWE-200"] = "Information Exposure",
    ["CWE-287"] = "Improper Authentication",
    ["CWE-327"] = "Use of a Broken or Risky Cryptographic Algorithm",
    ["CWE-352"] = "Cross-Site Request Forgery (CSRF)",
    ["CWE-434"] = "Unrestricted File Upload",
    ["CWE-502"] = "Deserialization of Untrusted Data",
    ["CWE-601"] = "Open Redirect",
    ["CWE-798"] = "Use of Hard-coded Credentials",
    ["CWE-918"] = "Server-Side Request Forgery (SSRF)",
}

--- Get CWE name from CWE ID
---@param cwe any
---@return string
function M.get_cwe(cwe)
    if not M.cwes[cwe] then
        return "Unknown - " .. cwe
    end
    return M.cwes[cwe]
end

return M
