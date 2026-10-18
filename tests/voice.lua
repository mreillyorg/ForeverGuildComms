-- Run from addon root: texlua tests/voice.lua
local base = (arg and arg[0] and arg[0]:match("^(.*[/\\])tests[/\\]voice%.lua$")) or "./"
_G.StaticPopupDialogs, _G.SlashCmdList = {}, {}
_G.CreateFrame = function() return {RegisterEvent=function()end, SetScript=function()end} end
local race = "Dwarf"
_G.UnitRace = function() return race, race, 3 end
local A = {}
for _, mod in ipairs({"Core.lua", "Languages.lua", "Accents.lua", "RaceProfiles.lua"}) do
    assert(loadfile(base .. mod))("ForeverGuildComms", A)
end
A.db = {templates={}}
for key, value in pairs(A.defaults.templates) do A.db.templates[key] = value end
A.char = {voice={language="en", accent="none", raceFilter=true, accentStrength="subtle"}}
assert(A:CommsText("login",{name="Bunky"}) == "Welcome back, Bunky!", "unchanged defaults should remain unchanged")
assert(A:SetVoiceOption("accent","dwarf"))
assert(A:CommsText("level",{name="Thorin",level=27}):find("forge",1,true), "Dwarf style should be used")
assert(not A:SetVoiceOption("accent","troll"), "race-filtered out accents cannot be set")
assert(A:SetVoiceOption("accentStrength", "expressive"))
assert(A:CommsText("login",{name="Thorin"}):find("By the forge!",1,true), "expressive accents add voice flavour")
assert(A:SetVoiceOption("raceFilter", false))
assert(A:SetVoiceOption("accent", "troll"), "unfiltered accents are available")
assert(A:CommsText("join", {name="Bob"}):find("mon",1,true), "unfiltered WoW race style")
assert(A:SetVoiceOption("language", "es"))
assert(A.char.voice.accent == "auto", "incompatible accents reset safely")
assert(A:CommsText("login", {name="Carlos"}):find("Bienvenido",1,true), "Spanish translations applied")
assert(A:CommsText("help", {type="Mazmorra",activity="Deadmines",myroles="Sanador",needed="Tanque"}):find("Sanador",1,true), "placeholder is not damaged")
assert(A:LocalizeRoleText({tank=true, healer=true},"flexible")=="Tanque/Sanador", "role labels translated")
assert(A:LocalizeActivityType("Quest")=="Misión", "activity labels translated")
race = "Human"
assert(A:SetVoiceOption("raceFilter", true))
assert(A:SetVoiceOption("accent", "mexican"), "human accents can be regionally filtered in their own language")
assert(A:CommsText("join",{name="Rosa"}):find("hermandad",1,true), "Mexican variant selected")
A.db.templates.join="Check |cff00ff00|Hitem:1|h[Linen Bag]|h|r, {name}!"
local custom = A:CommsText("join",{name="Rosa"})
assert(custom == "Check |cff00ff00|Hitem:1|h[Linen Bag]|h|r, Rosa!", "custom templates override translation and preserve item links")
A.db.templates.join=A.defaults.templates.join
assert(A:SetVoiceOption("accent", "none"))
assert(A:CommsText("join",{name="Rosa"}) == A:Format(A.localeTemplates.es.join, {name="Rosa"}), "no accent uses locale defaults")
race = "TotallyNewRace"
assert(#A:GetAvailableAccents() == 2 and A:ResolveAccent()==nil, "unknown races fall back safely")
-- Regression: never split a multibyte character halfway when cutting to 250 bytes.
local testString = string.rep("a",249) .. "é" .. "something"
local trimmed = A:ChatLimit(testString)
assert(trimmed == string.rep("a",249), "UTF-8 truncation is character-safe")
assert(not A:SetVoiceOption("language","zzz") and not A:SetVoiceOption("accentStrength","nonsense"),"bad values rejected")
print("PASSED: languages, regional and racial accent filtering, custom links, UTF-8, template variables, per-character voice settings")
