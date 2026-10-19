local _, A = ...
local citiesByName = {
    ["Stormwind City"]=true, ["Stormwind"]=true, ["Ironforge"]=true,
    ["Darnassus"]=true, ["Orgrimmar"]=true, ["Undercity"]=true,
    ["Thunder Bluff"]=true, ["The Exodar"]=true, ["Silvermoon City"]=true,
}
local citiesByMapID = { [84]=true, [85]=true, [87]=true, [88]=true,
    [89]=true, [90]=true, [103]=true, [110]=true }

local function inMajorCity()
    if C_Map and C_Map.GetBestMapForUnit then
        local id = C_Map.GetBestMapForUnit("player")
        if id and citiesByMapID[id] then return true end
    end
    local zone = GetRealZoneText and GetRealZoneText() or ""
    return citiesByName[zone] or false
end
local function guildTabardEquipped()
    -- Guild Tabard is item 5976 in the Vanilla-era ruleset. If Blizzard adds
    -- alternate guild tabards, additional item IDs can be added here.
    return GetInventoryItemID and GetInventoryItemID("player", 19) == 5976
end

StaticPopupDialogs["FGC_TABARD_CITY"] = {
    text = "You are in a capital city without your Guild Tabard equipped. Open your character equipment to put it on?",
    button1 = "Open Character", button2 = "Not now",
    OnAccept = function() if ToggleCharacter then ToggleCharacter("PaperDollFrame") end end,
    timeout = 0, whileDead = false, hideOnEscape = true, preferredIndex = 3,
}
StaticPopupDialogs["FGC_TABARD_EXIT"] = {
    text = "You have left the city and are wearing your Guild Tabard. Would you like to open your character equipment to take it off?",
    button1 = "Open Character", button2 = "Keep it on",
    OnAccept = function() if ToggleCharacter then ToggleCharacter("PaperDollFrame") end end,
    timeout = 0, whileDead = false, hideOnEscape = true, preferredIndex = 3,
}

function A:CheckTabard(initial)
    if not self.db or not self:CanUse() then return end
    local nowCity = inMajorCity()
    local before = self.wasInCity
    self.wasInCity = nowCity

    -- PLAYER_ENTERING_WORLD can schedule a 1.2-second transition check ahead
    -- of the 3-second login check. A login check must therefore be able to
    -- prompt even if the transition check already initialized wasInCity.
    local firstLoginCheck = initial and not self.tabardInitialCheckDone
    if firstLoginCheck then self.tabardInitialCheckDone = true end

    -- Show at most one city prompt per city stay, including if an ordinary
    -- zone transition check already displayed it before the initial check.
    if not nowCity then self.tabardCityPrompted = false end
    if nowCity then
        local enteredCity = before ~= nil and not before
        if (firstLoginCheck or enteredCity) and self.db.tabardInCity
            and not self.tabardCityPrompted and not guildTabardEquipped() then
            self.tabardCityPrompted = true
            StaticPopup_Show("FGC_TABARD_CITY")
        end
    elseif before and self.db.tabardOnExit and guildTabardEquipped() then
        StaticPopup_Show("FGC_TABARD_EXIT")
    end
end
function A:ScheduleTabardCheck()
    if self.tabardCheckScheduled then return end
    self.tabardCheckScheduled = true
    C_Timer.After(1.2, function()
        self.tabardCheckScheduled = false
        self:CheckTabard(false)
    end)
end
