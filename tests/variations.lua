-- Run from addon root: texlua tests/variations.lua
local base = (arg and arg[0] and arg[0]:match("^(.*[/\\])tests[/\\]variations%.lua$")) or "./"
_G.StaticPopupDialogs, _G.SlashCmdList = {}, {}
_G.CreateFrame = function() return {RegisterEvent=function()end, SetScript=function()end} end
_G.UnitRace = function() return "Human", "Human", 1 end
local A = {}
for _, module in ipairs({"Core.lua", "Languages.lua", "Accents.lua", "RaceProfiles.lua", "MessageVariants.lua", "UI.lua"}) do
    assert(loadfile(base .. module))("ForeverGuildComms", A)
end
A.db = {enabled=true, randomizeMessages=true, templates={}}
for kind, template in pairs(A.defaults.templates) do A.db.templates[kind] = template end
A.char = {voice={language="en", accent="none", raceFilter=false, accentStrength="subtle"},
          myRoles={healer=true}, needRoles={tank=true}}
A.playerName = "Tester"
A.playerClass = "PRIEST"
A.activityEdit = {GetText=function() return "Deadmines" end}
A.GetActivityType = function() return "Dungeon" end
A.requestPreview = {SetText=function(self, text) self.text = text end}
A.requestFrame = {Hide=function(self) self.hidden = true end, Show=function(self) self.hidden = false end}
A.CanUse = function() return true end
A.Now = function() return 500 end
local sent = {}
A.SendGuild = function(_, text) sent[#sent+1] = text; return true end

local vars = {name="Thorin", level=42, type="Dungeon", activity="Deadmines", myroles="Healer", needed="Tank"}
local kinds = {"login", "join", "level", "help"}
for _, language in ipairs(A.languages) do
    A.char.voice.language = language.id
    A.char.voice.accent = "none"
    for _, kind in ipairs(kinds) do
        local count = 1 + #(A.localeVariants[language.id][kind])
        local seen, last, examples = {}, nil, {}
        for _ = 1, count * 2 do
            local line = A:CommsText(kind, vars)
            assert(not seen[line], "repeat within shuffled bank for " .. language.id .. " " .. kind)
            assert(line ~= last, "adjacent repeat for " .. language.id .. " " .. kind)
            assert(not line:find("{name}",1,true) and not line:find("{level}",1,true), "placeholder unfilled")
            if kind == "help" then assert(line:find("Deadmines",1,true),"activity lost") end
            if kind == "level" then assert(line:find("42",1,true),"level lost") end
            examples[#examples+1] = line
            seen[line] = true
            last = line
            if #examples % count == 0 then seen = {} end
        end
    end
end

for _, id in ipairs(A.accentOrder) do
    local accent = A.accents[id]
    A.char.voice.language, A.char.voice.accent = accent.language, id
    for _, kind in ipairs(kinds) do
        assert(A.accentVariants[id] and #A.accentVariants[id][kind] > 0,
            "no variation for accent " .. id .. " " .. kind)
        local line1 = A:CommsText(kind, vars)
        local line2 = A:CommsText(kind, vars)
        assert(line1 ~= line2, "accent repeated before the bag was exhausted: " .. id .. " " .. kind)
        assert(not line1:find("{myroles}",1,true), "interpolation missing")
    end
end

-- Settings previews do not consume a random selection.
A.char.voice.language, A.char.voice.accent = "en", "none"
A.messageVariantBags = {}
assert(A:CommsText("login", vars, true) == "Welcome back, Thorin!")
assert(next(A.messageVariantBags) == nil, "Settings preview advanced shuffle")

-- An authored template wins over every translation and variant.
A.db.templates.login = "Hello |Hitem:2589|h[Linen Cloth]|h, {name}!"
local first = A:CommsText("login", vars)
assert(first == "Hello |Hitem:2589|h[Linen Cloth]|h, Thorin!")
assert(A:CommsText("login", vars) == first)
A.db.templates.login = A.defaults.templates.login
A.db.randomizeMessages = false
assert(A:CommsText("login", vars) == "Welcome back, Thorin!", "disabled wording variation")
A.db.randomizeMessages = true

-- Repeated redraws of the help composer cannot silently alter its Send text.
A.requestDraft = nil
A:UpdateRequestPreview()
local shown = A.requestPreview.text
assert(A:RequestText() == shown)
A:UpdateRequestPreview()
assert(A.requestPreview.text == shown, "preview changed on redraw")
A:SendHelpRequest()
assert(sent[1] == shown and A.requestDraft == nil, "sent text differs from approved preview")
A.lastManualRequest = nil
A:ShowRequest() -- new opening generates a new draft
assert(A.requestPreview.text ~= shown, "new composer opening should advance variant")
A.activityEdit = {GetText=function() return "Shadowfang Keep" end}
A:UpdateRequestPreview()
assert(A.requestPreview.text:find("Shadowfang Keep",1,true), "activity change not reflected")

print("PASSED: nonrepeating shuffle bags, all languages and accents, custom overrides, stable preview/send, settings sample")
