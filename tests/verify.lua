-- Offline tests for manual approval, rollback to manual when mode changes,
-- and guild change safeguards. Run: texlua tests/verify.lua
local base = (arg and arg[0] and arg[0]:match("^(.*[/\\])tests[/\\]verify%.lua$")) or "./"
_G.print = print
_G.StaticPopupDialogs = {}
_G.SlashCmdList = {}
_G.GetTime = (function() local n=1000; return function() n=n+1; return n end end)()
_G.GetGuildInfo = function() return _G.testGuild end
_G.IsInGuild = function() return _G.testGuild ~= nil end
_G.testGuild = "Guild A"
_G.C_Timer = {
    scheduled = {},
    After = function(delay, callback) table.insert(_G.C_Timer.scheduled, callback) end,
    NewTicker = function() end,
}
_G.SendChatMessage = function(text, channel)
    assert(channel == "GUILD")
    table.insert(_G.sent, text)
end
_G.sent = {}
_G.wipe = function(t) for k in pairs(t) do t[k]=nil end end
_G.CreateFrame = function()
    return {RegisterEvent=function()end, SetScript=function()end}
end
local A = {}
assert(loadfile(base .. "Core.lua"))("ForeverGuildComms", A)
for _, module in ipairs({"Languages.lua", "Accents.lua", "RaceProfiles.lua"}) do
    assert(loadfile(base .. module))("ForeverGuildComms", A)
end
A.db = {enabled=true, outgoingMode="verify", messageSpacing=6}
A.UpdateBroker = function() end
local shown = 0
A.ShowApprovals = function() shown = shown + 1 end
assert(A:CanUse())
A:QueueGuild("Welcome Alice", "login:alice", 300)
assert(#A.pendingApprovals == 1 and #_G.sent == 0 and shown == 1, "verify must not auto-send")
A:QueueGuild("Welcome Alice", "login:alice", 300)
assert(#A.pendingApprovals == 1, "duplicate login should not be queued")
A:ApproveMessage(1)
assert(#_G.sent == 1 and _G.sent[1] == "Welcome Alice" and #A.pendingApprovals == 0, "send approval")
A:QueueGuild("Welcome Bob", "join:bob", 300)
A:DismissMessage(1)
assert(#_G.sent == 1 and #A.pendingApprovals == 0, "dismiss must not send")
A:QueueGuild("Congrats Eve", "level:eve:26", 120)
A.db.outgoingMode = "automatic"
assert(#_G.sent == 1 and #A.pendingApprovals == 1, "mode toggle cannot auto-send old pending messages")
A:ApproveMessage(1)
assert(#_G.sent == 2 and #A.pendingApprovals == 0, "older pending entry may be manually approved")
A:QueueGuild("Welcome Carl", "login:carl", 300)
assert(#A.pendingMessages == 1 and #_G.sent == 2, "automatic should enqueue")
A.db.outgoingMode = "verify"
assert(#_G.C_Timer.scheduled == 1)
local timer = table.remove(_G.C_Timer.scheduled, 1)
timer()
assert(#_G.sent == 2 and #A.pendingApprovals == 1, "mode switch during automatic delay must require approval")
_G.testGuild = "Guild B"
A:ApproveMessage(1)
assert(#_G.sent == 2 and #A.pendingApprovals == 0, "cannot send queued message to different guild")
A:QueueGuild("Guild B hello", "login:iris", 300)
assert(#A.pendingApprovals == 1)
A:ClearApprovals()
assert(#A.pendingApprovals == 0, "guild change clears approval")
A.db.outgoingMode = "automatic"
A:QueueGuild("Guild B automatic", "login:jill", 300)
local timer2 = table.remove(_G.C_Timer.scheduled, 1)
assert(timer2)
timer2()
assert(_G.sent[3] == "Guild B automatic", "automatic should send without click")
print("PASSED: confirmation, dedup, click to send, dismiss, mode switch, guild change, automatic sending")
