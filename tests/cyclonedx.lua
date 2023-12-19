local cyclonedx = require "devsecinspect.utils.cyclonedx"

local data = {
    components = {
        {
            ["bom-ref"] = "598f1978-6e77-440c-99aa-ac2fa7cf3374",
            name = "werkzeug",
            type = "library",
            version = "2.0.2",
        },
    },
    metadata = {
        timestamp = "2023-12-19T21:57:51.298177+00:00",
        name = "cyclonedx-python-lib",
        vendor = "CycloneDX",
        version = "4.2.3",
    },
    serialNumber = "urn:uuid:2e6860cd-f7f6-475b-ac5f-4db6908a1190",
    version = 1,
    vulnerabilities = {
        {
            ["bom-ref"] = "598f1978-6e77-440c-99aa-ac2fa7cf3374",
            description = "Werkzeug is a comprehensive WSGI web application library...",
            id = "PYSEC-2023-221",
            recommendation = "Upgrade",
        },
    },
}

describe("CycloneDX", function()
    it("should return a valid CycloneDX JSON", function()
        local results = cyclonedx.processJson(data, "", {})
        eq(1, #results)
        eq("werkzeug", results[1].name)
    end)
end)
