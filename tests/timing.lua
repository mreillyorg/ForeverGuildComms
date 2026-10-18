-- Timing behaviour: run with texlua tests/timing.lua
local base = (arg and arg[0] and arg[0]:match("^(.*[/\\])tests[/\\]timing%.lua$")) or "./"
_G.StaticPopupDialogs, _G.SlashCmdList = {}, {}
local now = 100
_G.GetTime = function() return now end
_G.IsInGuild = function() return true end
_G.GetGuildInfo = function() return "Example Guild" end
_G.sent = {}
_G.SendChatMessage = function(message, channel)
    assert(channel == "GUILD")
    table.insert(sent, message)
end
_G.C_Timer = {scheduled={}, After=function(delay, callback)
    table.insert(C_Timer.scheduled, {delay=delay, callback=callback})
end}
_G.CreateFrame = function()
    return {RegisterEvent=function() end, SetScript=function() end}
end
local A = {}
assert(loadfile(base.."Core.lua"))("ForeverGuildComms", A)
for _, module in ipairs({"Languages.lua", "Accents.lua", "RaceProfiles.lua"}) do
    assert(loadfile(base .. module))("ForeverGuildComms", A)
end
A.db = {enabled=true, outgoingMode="automatic", messageSpacing=12, loginCooldown=60}
local function runNext(expectedDelay)
    assert(#C_Timer.scheduled > 0, "expected queue timer")
    local timer = table.remove(C_Timer.scheduled, 1)
    assert(timer.delay == expectedDelay,
        "expected delay " .. expectedDelay .. ", got " .. tostring(timer.delay))
    timer.callback()
end
A:QueueGuild("Hello Alice", "login:alice", A.db.loginCooldown)
runNext(0)
assert(#sent == 1 and sent[1] == "Hello Alice")
now = 101
A:QueueGuild("Hello Bob", "login:bob", A.db.loginCooldown)
runNext(11)
now = 112
A:QueueGuild("Hello Carol", "login:carol", A.db.loginCooldown)
-- Bob's callback advanced lastGuildSend while now was 101; the queue
-- computes the third message relative to the real timestamp on invocation.
runNext(1)
now = 113
A:QueueGuild("Hello Alice again", "login:alice", A.db.loginCooldown)
assert(#sent == 3 and #C_Timer.scheduled == 0, "login cooldown prevents repeated hello")
now = 161
A:QueueGuild("Hello Alice later", "login:alice", A.db.loginCooldown)
runNext(0)
assert(#sent == 4 and sent[4] == "Hello Alice later")
A.db.loginCooldown = 0
now = 162
A:QueueGuild("Hello Alice cooldown off", "login:alice", A.db.loginCooldown)
runNext(11)
assert(#sent == 5, "zero login cooldown allows future login events")
print("PASSED: automatic message spacing, per-member login cooldown, zero cooldown")
