-- Static icon wiring checks (run from the addon's repository root).
local function readFile(path)
    local f = assert(io.open(path, "rb"), path)
    local text = f:read("*a")
    f:close()
    return text
end
local toc = readFile("ForeverGuildComms.toc")
local broker = readFile("Broker.lua")
local options = readFile("Options.lua")
local installer = readFile("install/Install-ForeverGuildComms.ps1")
assert(toc:find("## IconTexture: Interface\\AddOns\\ForeverGuildComms\\Media\\Icon", 1, true))
assert(broker:find("Interface\\\\AddOns\\\\ForeverGuildComms\\\\Media\\\\Icon", 1, true))
assert(options:find("addonIcon:SetTexture", 1, true))
assert(installer:find("Media\\Icon.tga", 1, true))
for _, path in ipairs({"Media/Icon.tga", "Media/ProjectIcon.png"}) do
    local f = assert(io.open(path, "rb"), "Missing texture: " .. path)
    assert(f:seek("end") > 1024, "Unexpected tiny texture: " .. path)
    f:close()
end
print("icon test passed")
