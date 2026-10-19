-- Compile every addon source file, without running it.
local base = (arg and arg[0] and arg[0]:match("^(.*[/\\])tests[/\\]syntax%.lua$")) or "./"
for _, filename in ipairs({"Core.lua", "Languages.lua", "Accents.lua", "RaceProfiles.lua", "MessageVariants.lua", "Roster.lua", "Alerts.lua", "Tabard.lua", "UI.lua", "Options.lua", "TitanMenu.lua", "Broker.lua"}) do
    assert(loadfile(base .. filename), "Lua syntax error in " .. filename)
end
print("PASSED: all addon files compile")
