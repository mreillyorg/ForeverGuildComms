-- Regression tests: tabard login scheduling + bounded event deduplication.
-- Run from addon directory: texlua tests/tabard_dedup.lua
local base = (arg and arg[0] and arg[0]:match("^(.*[/\\])tests[/\\]tabard_dedup%.lua$")) or "./"
_G.StaticPopupDialogs, _G.SlashCmdList = {}, {}
local now = 100
local zone = "Stormwind City"
local tabard = nil
local prompts = {}
local timers = {}
_G.GetTime = function() return now end
_G.IsInGuild = function() return true end
_G.GetRealZoneText = function() return zone end
_G.GetInventoryItemID = function(_, slot) if slot == 19 then return tabard end end
_G.StaticPopup_Show = function(id) prompts[#prompts + 1] = id end
_G.C_Timer = {
    After = function(delay, fn) timers[#timers + 1] = {delay=delay, callback=fn} end,
    NewTicker = function() end,
}
_G.CreateFrame = function() return {RegisterEvent=function()end, SetScript=function()end} end
local A = {}
assert(loadfile(base .. "Core.lua"))("ForeverGuildComms", A)
assert(loadfile(base .. "Tabard.lua"))("ForeverGuildComms", A)
A.db = {enabled=true, tabardInCity=true, tabardOnExit=true}

-- Reproduce 1.2s zone check running BEFORE delayed 3s initial login check.
A:ScheduleTabardCheck()
assert(#timers == 1 and timers[1].delay == 1.2)
table.remove(timers, 1).callback()
assert(A.wasInCity == true and #prompts == 0, "debounced check initializes the city flag without prompting")
A:CheckTabard(true)
assert(#prompts == 1 and prompts[1] == "FGC_TABARD_CITY",
    "late login-time check still prompts even though wasInCity is already true")
A:CheckTabard(true)
A:CheckTabard(false)
assert(#prompts == 1, "no duplicate prompts during a single city stay")

-- Exit with tabard equipped prompts; re-enter un-equipped prompts again.
zone = "Elwynn Forest"
tabard = 5976
A:CheckTabard(false)
assert(#prompts == 2 and prompts[2] == "FGC_TABARD_EXIT", "exit reminder still works")
zone = "Stormwind City"
tabard = nil
A:CheckTabard(false)
assert(#prompts == 3 and prompts[3] == "FGC_TABARD_CITY", "new city visit may prompt again")

-- When a normal transition prompts before the delayed initial check, it must
-- NOT produce a second prompt at login.
A.wasInCity = false
A.tabardInitialCheckDone = false
A.tabardCityPrompted = false
A:CheckTabard(false)
assert(#prompts == 4 and prompts[4] == "FGC_TABARD_CITY")
A:CheckTabard(true)
assert(#prompts == 4, "initial check must not re-show an already displayed city prompt")

-- No city reminder when outside or already wearing the guild tabard.
A.wasInCity, A.tabardInitialCheckDone, A.tabardCityPrompted = nil, false, false
zone, tabard = "Elwynn Forest", nil
A:CheckTabard(true)
assert(#prompts == 4, "no initial reminder outside city")
A.wasInCity, A.tabardInitialCheckDone, A.tabardCityPrompted = nil, false, false
zone, tabard = "Stormwind City", 5976
A:CheckTabard(true)
assert(#prompts == 4, "no initial reminder if equipped")

-- Duplicate entries are retained during the maximum supported cooldown, then
-- removed at/after one hour. A reduced cooldown doesn't shorten the retention
-- when the user might later increase loginCooldown in Settings.
A.eventsSeen, A.lastEventPrune = {}, nil
now = 1000
assert(not A:IsDuplicate("login:alice", 300))
assert(A:IsDuplicate("login:alice", 3600))
now = 1300
assert(A:IsDuplicate("login:alice", 3600), "older event remains blocked after cooldown increases")
assert(not A:IsDuplicate("join:bob", 300))
now = 4599
A:PruneEventsSeen(now)
assert(A.eventsSeen["login:alice"] == 1000, "retain entry before 3600s expiry")
assert(A.eventsSeen["join:bob"] == 1300)
-- Sweeps are intentionally throttled to once per 60 seconds.
now = 4659
A:PruneEventsSeen(now)
assert(A.eventsSeen["login:alice"] == nil, "expired event pruned on next sweep")
assert(A.eventsSeen["join:bob"] == 1300, "other more recent event preserved")
now = 4900
A:PruneEventsSeen(now)
assert(next(A.eventsSeen) == nil, "all stale keys eventually removed")
now = 5000
assert(not A:IsDuplicate("login:alice", 300), "expired login event can be re-added")
assert(A:IsDuplicate("login:alice", 300), "fresh repeated login event still suppressed")

-- Invalid and forward-dated values are dropped; GetTime discontinuity can
-- happen between reloads or after an unusual clock reset.
A.eventsSeen["bad"] = "invalid"
A.eventsSeen["future"] = now + 500
now = 5100
A:PruneEventsSeen(now)
assert(A.eventsSeen.bad == nil and A.eventsSeen.future == nil, "malformed/future timestamps discarded")
-- Initialize also schedules an idle-session pruning ticker, so the cache
-- shrinks even when guild chat stays quiet after a burst of events.
local tickerPeriod, tickerCallback
C_Timer.NewTicker = function(period, callback)
    tickerPeriod, tickerCallback = period, callback
end
_G.UnitGUID = function() return "Player-987" end
_G.UnitName = function() return "Hero" end
_G.UnitClass = function() return "Mage", "MAGE" end
local B = {}
assert(loadfile(base .. "Core.lua"))("ForeverGuildComms", B)
B:Initialize()
assert(tickerPeriod == 300 and type(tickerCallback) == "function", "idle cleanup ticker registered")
B.eventsSeen["level:old:2"] = 1000
now = 6000
tickerCallback()
assert(B.eventsSeen["level:old:2"] == nil, "idle timer prunes old events")
print("PASSED: tabard login ordering, repeat suppression, city exits/re-entry, event pruning")
