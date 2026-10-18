-- Offline Lua smoke tests; run with: texlua tests/smoke.lua
local base = (arg and arg[0] and arg[0]:match("^(.*[/\\])tests[/\\]smoke%.lua$")) or "./"
_G.print = print
_G.StaticPopupDialogs = {}
_G.SlashCmdList = {}
_G.UnitName = function() return "Hero" end
_G.UnitGUID = function() return "Player-123" end
_G.UnitClass = function() return "Mage", "MAGE" end
_G.GetTime = (function() local n=1000; return function() n=n+1; return n end end)()
_G.IsInGuild = function() return true end
_G.GetGuildInfo = function() return "TestGuild" end
_G.C_Timer = { After = function(_delay, callback) callback() end, NewTicker=function()end }
_G.SendChatMessage = function() end
_G.wipe = function(t) for k in pairs(t) do t[k]=nil end end
_G.CreateFrame = function()
  return {RegisterEvent=function()end, SetScript=function()end}
end
_G.ERR_GUILD_JOIN_S = "%s has joined the guild."
_G.date = function() return "12:00" end
local A = {}
assert(loadfile(base .. "Core.lua"))("ForeverGuildComms", A)
assert(loadfile(base .. "Roster.lua"))("ForeverGuildComms", A)
assert(loadfile(base .. "Alerts.lua"))("ForeverGuildComms", A)
A.db = {enabled=true, greetLogin=true, greetJoin=true, congratulateLevel=true, craftingAlerts=true, groupAlerts=true,
  loginCooldown=300, templates={login="Welcome {name}", join="Hello {name}", level="Grats {name}: {level}"}}
A.char = {recipes={Tailoring={['linen bag']='Linen Bag'}}}
A.playerGuid = "Player-123"; A.playerKey = A:Key("Hero"); A.playerName="Hero"
local queue = {}
A.QueueGuild = function(_, msg) queue[#queue+1]=msg end
A.rosterReady = true
A:AcceptRoster({
  hero = {name="Hero", level=20, online=true, guid="Player-123"},
  alice = {name="Alice", level=21, online=false, guid="Other-1"},
  bob = {name="Bob", level=17, online=true, guid="Other-2"}
}, 3, 2, true)
A:AcceptRoster({
  hero = {name="Hero", level=21, online=true, guid="Player-123"},
  alice = {name="Alice", level=21, online=true, guid="Other-1"},
  bob = {name="Bob", level=18, online=true, guid="Other-2"}
}, 3, 3, false)
assert(#queue == 2, "expected Alice login and Bob level, not Hero level: " .. #queue)
assert(queue[1] == "Welcome Alice" or queue[2] == "Welcome Alice")
assert(queue[1] == "Grats Bob: 18" or queue[2] == "Grats Bob: 18")
A:OnSystemGuildJoin("Carol has joined the guild.")
assert(#queue == 3 and queue[3] == "Hello Carol", "localized join parser")
A:OnSystemGuildJoin("Hero has joined the guild.")
assert(#queue == 3, "self should not receive guild join message")
local alerts = {}
A.AddAlert = function(_, kind, sender, text)
  alerts[#alerts+1] = {kind=kind,sender=sender,text=text}
end
A:OnGuildChat("Can anyone craft a [Linen Bag]?", "Alice")
assert(#alerts == 1 and alerts[1].kind == "Craft: Linen Bag", "craft request detection")
A:OnGuildChat("LFG Deadmines - need tank", "Bob")
assert(#alerts == 2 and alerts[2].kind == "Group request", "group request detection")
A:OnGuildChat("LFG Deadmines - need tank", "Hero")
assert(#alerts == 2, "self chat should not alert")
_G.C_TradeSkillUI = {
  GetAllRecipeIDs=function() return {100, 101} end,
  GetRecipeInfo=function(id)
    if id == 100 then return {learned=true, disabled=false, name="Linen Bag"} end
    return {learned=false, disabled=false, name="Unlearned Item"}
  end,
  GetRecipeItemLink=function(id)
    if id == 100 then return "|cffaaa|Hitem:423|h[Linen Bag]|h|r" end
    return "|cffaaa|Hitem:555|h[Unlearned Item]|h|r"
  end,
}
A:ScanRecipes()
assert(A.char.recipes["Current Profession"]["linen bag"] == "Linen Bag", "learned recipe cached")
assert(not A.char.recipes["Current Profession"]["unlearned item"], "unlearned recipe not cached")
print("PASSED: self level-up excluded, login, other level-up, join, craft, group, self chat, recipe learned check")
