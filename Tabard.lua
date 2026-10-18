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
    if before == nil then
        self.wasInCity = nowCity
        if not initial then return end
        if nowCity and self.db.tabardInCity and not guildTabardEquipped() then
            StaticPopup_Show("FGC_TABARD_CITY")
        end
        return
    end
    if before == nowCity then return end
    self.wasInCity = nowCity
    if nowCity and self.db.tabardInCity and not guildTabardEquipped() then
        StaticPopup_Show("FGC_TABARD_CITY")
    elseif not nowCity and self.db.tabardOnExit and guildTabardEquipped() then
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
